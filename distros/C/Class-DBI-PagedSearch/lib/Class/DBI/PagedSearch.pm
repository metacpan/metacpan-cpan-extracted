package Class::DBI::PagedSQLSearch;
use strict;
use warnings;

our $VERSION = '1.000';

=head1 NAME

Class::DBI::PagedSearch - pageable results from searches

=head1 SYNOPSIS

  package MyClass;
  use base 'Class::DBI';
  use Class::DBI::PagedSearch;
  
  # more setup of MyClass here.


  # meanwhile, elsewhere...
  package main;
  use Data::Page;
  
  # create a new pager object
  my $page = Data::Page->new();
  
  # we want only 10 entries per page
  $page->entries_per_page(10);
  
  # get page number 4
  $page->current_page(4);
  
  # MyClass isa Class::DBI object where 
  MyClass->search( species => 'camel', { pager => $page });

=head1 DESCRIPTION

Override Class::DBI::search to provide pagable results. An optional Data::Page
object is passed in as the hash argument at the end of the option, and its
C<total_entries> attribute will be populated after the query.

  MyClass->search(%where, { order_by => '', pager => $page })

It also provides a method that allows paging raw sql queries.  Use this instead
of set_sql if you need paging.

  MyClass->search_sql($sql, @arg, { pager => $page })


=head1 DEFAULT SEARCH ATTRIBUTES

If your class has a class getter called C<default_search_attributes>, this
plugin will use the attributes defined there as default to search by. An
example use of this can be:

  __PACKAGE__->default_search_attributes(
    { order_by => ['created_datetime ASC'] }
  );

to ensure that all searches on this class will order the results ascendingly by
created_datetime column. You can always override these defaults.

=cut


use base 'Class::DBI::Search::Basic';
use SQL::Abstract;
__PACKAGE__->mk_accessors(qw/_sql/);

sub new {
    my ($me, $proto, @args) = @_;
    my ($args, $opts, $sql) = $me->_unpack_args(ref $proto || $proto, @args);
    bless {
            class => ref $proto || $proto,
            args  => $args,
            opts  => $opts,
            type  => "=",
            _sql  => $sql,
    } => $me;
}

sub _unpack_args {
    my (undef, $class, $sql, @args) = @_;
    my $opts = ($#args > 0 && ref($args[-1]) eq 'HASH') ? pop @args : {};
    if ($class->can('default_search_attributes')) {
      $opts = {%{$class->default_search_attributes}, %$opts};
    }
    return (\@args, $opts, $sql);
}

sub bind {
    my $self = shift;
    return $self->args;
}

# We are not really using this as a cdbi plugin, just need the syntax
# for paging.  So workaround the bits that the plugin registers itself
# with a normal cdbi class.
require Class::DBI::Plugin::Pager;
Class::DBI::Plugin::Pager->_pager_class( 'Class::DBI::Plugin::Pager' );

sub sql {
    my $self = shift;
    my $sql = $self->_sql;
    my $arg = $self->opts;
    my $proto = $self->class;
    my $page_syntax;

    if (my $page = $arg->{pager}) {
        my $pager = Class::DBI::Plugin::Pager::pager($proto);
        $pager->entries_per_page( $page->entries_per_page );
        $pager->current_page( $page->_current_page_accessor);
        # populate total_entries
        my $count = "SELECT count(*) FROM ( $sql ) zaphod_count";
        my $sth = $proto->db_Main->prepare($count);

        $page->total_entries($sth->select_val(@{ $self->bind }));
        $pager->total_entries($page);

        my $syntax   = $pager->_syntax || $pager->set_syntax;
        $page_syntax = $pager->$syntax;
    }

    if (my $order = $arg->{order_by}) {
        $order = [$order] unless ref($arg->{order_by});
        $sql .= ' ORDER BY '.join(',', map {$proto->table.'.'.$_ } @$order);
    }

    $sql .= ' '.$page_syntax if $page_syntax;

    if (my $prefetch = $arg->{prefetch}) {
        # put the prefetch spec in _zoj field, as the essential fields
        # in encoded field names, let _init vivify the object with
        # those fields preloaded.
        my $pref = ", '".join(' ', @$prefetch)."' AS _zoj";
        my $joins = '';
        my $jnum = 1;
        for my $pre (@$prefetch) {
            my $meta = $proto->meta_info(has_a => $pre);
            my $f_class = $meta->{foreign_class};
            $joins .= ' LEFT JOIN '.$f_class->table.' AS _zoj_'.$f_class->table.' ON ('.$proto->table.'.'.$pre.'=_zoj_'.$f_class->table.'.'.($f_class->primary_columns)[0].")\n";
            foreach my $col ($f_class->columns('Essential')) {
                $pref .= ", _zoj_".$f_class->table.".${col} AS _zoj_${jnum}_${col}";
            }
            ++$jnum;
        }
        $sql =~ s/\bFROM\b/$pref FROM/i;
        $sql =~ s/\bWHERE\b/$joins WHERE/i
            or $sql .= $joins; # if there no where
    }

    return $proto->db_Main->prepare($sql);
}


package Class::DBI::PagedSearch;
use base 'Class::DBI::PagedSQLSearch';

sub import {
    my $class = shift;
    local $Exporter::ExportLevel = 1;
    if (caller(0)->isa('Class::DBI')) {
        caller(0)->add_searcher(
            search     => "Class::DBI::PagedSearch",
            search_sql => "Class::DBI::PagedSQLSearch",
        );
    }
    $class->SUPER::import(@_);
}

sub _unpack_args {
    shift; # ignore first arg
    my $class = shift;
    my $opts = ($#_ > 0 && ref($_[-1]) eq 'HASH') ? pop @_ : {};
    my @args = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
    if ($class->can('default_search_attributes')) {
        $opts = {%{$class->default_search_attributes}, %$opts};
    }
    return (\@args, $opts);
}

sub new {
    my $self = shift->SUPER::new(@_);
    my $searchfor = $self->_search_for;

    my $where = {};
    for (keys %$searchfor) {
        $where->{ $self->class->table . '.' . $_ } = $searchfor->{$_};
    }

    my ($do_cache, $key);
    my $cache;
    $cache = $self->class->cache_by_key if $self->class->can('cache_by_key');
    if (keys %$cache && (keys %$searchfor = 1)) {
        my $field;
        ($field, $key) = %$searchfor;
        if ($do_cache = $cache->{$field}) {
            return $do_cache->{$key} if exists $do_cache->{$key};
        }
    }

    my $sqlabstract = SQL::Abstract->new({});
    my ( $phrase, @bind ) = $sqlabstract->where( $where );
    utf8::upgrade($_) for @bind;

    my $sql = join(' ', 'SELECT',
                   join(',', map {$self->class->table.'.'.$_} $self->class->_essential),
                   'FROM', $self->class->table,
                   $phrase);
                   
    $self->_sql( $sql );
    $self->args( \@bind );
    return $self;


# 
#     if ($do_cache) {
#       die "cache for $self with more than one result!"
#           if $#ret > 0;
#       $do_cache->{$key} = $ret[0]
#           if $#ret == 0;
#     }

}

1;

__END__

=head1 BUGS

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-PagedSearch>

=head1 AUTHOR EMERITUS

Chia-liang Kao C<clkao@clkao.org>

=head1 AUTHOR

Fotango Ltd. C<cpan@fotango.com>

If you're reporting bugs I<please> use the RT system mentioned above so
we can track the issues you report.

=head1 COPYRIGHT / LICENSE

Copyright Fotango 2005-2006.  All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
