package Class::DBI::Sweet::More;
use warnings;
use strict;

our $VERSION = '0.01';
use base qw/Class::DBI::Sweet/;

sub _search {
    my $proto      = shift;
    my $criteria   = shift;
    my $attributes = shift;
    my $class      = ref($proto) || $proto;

    # Valid SQL::Abstract params
    my %params = map { $_ => $attributes->{$_} } qw(case cmp convert logic);

    $params{cdbi_class}    = $class;
    $params{cdbi_me_alias} = 'me';

    # Overide bindtype, we need all columns and values for deflating
    my $abstract =
      Class::DBI::Sweet::More::SQL::Abstract->new( %params, bindtype => 'columns' );

    my ( $sql, $from, $classes, @bind ) =
      $abstract->where( $criteria, '', $attributes->{prefetch} );

    my ( @columns, @values, %cache );

    foreach my $bind (@bind) {
        push( @columns, $bind->[0] );
        push( @values,  @{$bind}[ 1 .. $#$bind ] );
    }

    unless ( $sql =~ /^\s*WHERE/i )
    {    # huh? This is either WHERE.. or empty string.
        $sql = "WHERE 1=1 $sql";
    }

    $sql =~ s/^\s*(WHERE)\s*//i;

    my %sql_parts = (
        where    => $sql,
        from     => $from,
        limit    => '',
        order_by => '',
    );

    $sql_parts{order_by} = $abstract->_order_by( $attributes->{order_by} )
      if $attributes->{order_by};

    if ( $attributes->{rows} && !$attributes->{disable_sql_paging} ) {

        my $rows   = $attributes->{rows};
        my $offset = $attributes->{offset} || 0;
        my $driver = lc $class->db_Main->{Driver}->{Name};

        if ( $driver =~ /^(maxdb|mysql|mysqlpp)$/ ) {
            $sql_parts{limit} = ' LIMIT ?, ?';
            push( @columns, '__OFFSET', '__ROWS' );
            push( @values, $offset, $rows );
        }

        elsif ( $driver =~ /^(pg|pgpp|sqlite|sqlite2)$/ ) {
            $sql_parts{limit} = ' LIMIT ? OFFSET ?';
            push( @columns, '__ROWS', '__OFFSET' );
            push( @values, $rows, $offset );
        }

        elsif ( $driver =~ /^(interbase)$/ ) {
            $sql_parts{limit} = ' ROWS ? TO ?';
            push( @columns, '__ROWS', '__OFFSET' );
            push( @values, $rows, $offset + $rows );
        }
    }

    return ( \%sql_parts, $classes, \@columns, \@values );
}


package Class::DBI::Sweet::More::SQL::Abstract;
use base qw/Class::DBI::Sweet::SQL::Abstract/;

sub where {
      my ($self, $where, $order, $must_join) = @_;
      my $me = $self->{cdbi_me_alias};
      $self->{cdbi_table_aliases} = { $me => $self->{cdbi_class} };
      $self->{cdbi_join_info}     = { };
      $self->{cdbi_column_cache}  = { };

      foreach my $join (@{$must_join || []}) {
        $self->_resolve_join($me => $join);
      }

## add
{
      my $l_alias = $me;
      my $l_class = $self->{cdbi_class};
      my $meta = $l_class->meta_info;
      foreach my $colum (keys %$where) {
        my $val = $where->{ $colum };
        next unless ref $val eq 'HASH';
        next unless exists $val->{'-and'} and ref $val->{'-and'} eq 'ARRAY';

        my ($f_alias, $match_col) = $colum =~ m/^(.+?)\.(.+)$/x;
        next unless $meta->{has_many}{$f_alias};

        my $match_list  = delete $val->{'-and'};
        my $match_count = scalar @$match_list;

        for my $i (1 .. $match_count) {
          my $new_f_alias = "${f_alias}__$i";

          my $new_match_col = $match_col;
          if ($match_col =~ m/^(.+?)\.(.+)$/x) {
            $new_match_col = "$1__$i.$2";
          }
          $where->{"$new_f_alias.$new_match_col"} = shift @$match_list;
        }
      }
}
## end

      my $sql = '';
      my (@ret) = $self->_recurse_where($where);

      if (@ret) {
        my $wh = shift @ret;
        $sql .= $self->_sqlcase(' where ') . $wh if $wh;
      }

      $sql =~ s/(\S+)( IS(?: NOT)? NULL)/$self->_default_tables($1).$2/ge;

      my $joins  = delete $self->{cdbi_join_info};
      my $tables = delete $self->{cdbi_table_aliases};

      my $from = $self->{cdbi_class}->table." ${me}";

    ## add
    foreach my $join ( keys %{$joins} ) {
        next unless $joins->{$join}{join_type};

        my $table = $tables->{$join}->table;
        my $join_data = delete $joins->{$join};
        my ( $l_alias, $l_key, $f_key, $join_type ) =
        	@{$join_data}{qw/l_alias l_key f_key join_type/};

        $from .= " ${join_type} JOIN ${table} ${join} ON ${l_alias}.${l_key} = ${join}.${f_key}";
    }
    # end

      foreach my $join (keys %{$joins}) {
        my $table = $tables->{$join}->table;

        $from .= ", ${table} ${join}";
        my ($l_alias, $l_key, $f_key) =
             @{$joins->{$join}}{qw/l_alias l_key f_key/};
        $sql .= " AND ${l_alias}.${l_key} = ${join}.${f_key}";
      }

      # order by?
      #if ($order) {
      #    $sql .= $self->_order_by($order);
      #}

      delete $self->{cdbi_column_cache};

      return wantarray ? ($sql, $from, $tables, @ret) : $sql;
}

sub _resolve_join {
    my $self = shift;
    my ($l_alias, $f_alias) = @_;

    my $l_class = $self->{cdbi_table_aliases}->{$l_alias};
    my $meta = $l_class->meta_info;

    ## add
    my $org_f_alias = $f_alias;
    if ($f_alias =~ /^(.+?)__\d+$/) {
        $f_alias = $1;
    }

    my ($rel, $f_class);
    if ($rel = $meta->{has_a}{$f_alias}) {
        $f_class = $rel->foreign_class;
        #$self->{cdbi_join_info}{$f_alias} = {
        $self->{cdbi_join_info}{$org_f_alias} = {	# modify
            l_alias => $l_alias,
            l_key => $f_alias,
            f_key => ($f_class->columns('Primary'))[0]
        };
    }
    elsif ($rel = $meta->{has_many}{$f_alias}) {
        $f_class = $rel->foreign_class;
        #$self->{cdbi_join_info}{$f_alias} = {
        $self->{cdbi_join_info}{$org_f_alias} = {	# modify
            l_alias => $l_alias,
            l_key => ($l_class->columns('Primary'))[0],
            f_key => $rel->args->{foreign_key},
            join_type => $rel->args->{join_type} || '',	# add
        };
    }
    elsif ($rel = $meta->{might_have}{$f_alias}) {
        $f_class = $rel->foreign_class;
        #$self->{cdbi_join_info}{$f_alias} = {
        $self->{cdbi_join_info}{$org_f_alias} = {	# modify
            l_alias => $l_alias,
            l_key => ($l_class->columns('Primary'))[0],
            f_key => ($f_class->columns('Primary'))[0],
            join_type => $rel->args->{join_type} || '',	# add
        };
    }
    else {
        croak("Unable to find join info for ${f_alias} from ${l_class}");
    }

    #$self->{cdbi_table_aliases}{$f_alias} = $f_class;
    $self->{cdbi_table_aliases}{$org_f_alias} = $f_class;	# modify
}

1; # End of Class::DBI::Sweet::More
__END__

=head1 NAME

Class::DBI::Sweet::More - More sweet Class::DBI::Sweet

=head1 SYNOPSIS

    package MyApp::DBI;
    use base 'Class::DBI::Sweet::More'; # change from Class::DBI::Sweet

    ...

    # LEFT OUTER JOIN
    MyApp::CD->has_many(tags => 'MyApp::Tag', {join_type => 'LEFT'});
    MyApp::CD->might_have(liner_notes
        => 'MyApp::LinerNotes' => qw/notes/)->{args}{join_type} = 'LEFT';

    # This is selected not to have tags.
    my @cds = MyApp::CD->search({'tags' => undef});

    # This succeeds even without liner_notes.
    my ($cd) = MyApp::CD->search( { ... },
                       { prefetch => [ qw/liner_notes/ ] } );

    # This is selected to have tags of Blue and Cheesy.
    my @cds = MyApp::CD->search({'tags.tag' => {-and => [qw/ Blue Cheesy /]} });


=head1 DESCRIPTION

Class::DBI::Sweet::More provides OUTER JOIN
(and has_many table's search option '-and')
to C<Class::DBI::Sweet>.

=head1 AUTHOR

ASAKURA Takuji, C<< <asakura.takuji+cpan at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 ASAKURA Takuji, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
