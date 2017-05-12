package DBIx::MoCo::Pageset;

use warnings;
use strict;

our $VERSION = '0.01';
our $AUTOLOAD;

our $PAGER_IMPLEMENTATION = 'Data::Pageset';

sub _croak { require Carp; Carp::croak(@_); }

sub import {
    my $class = shift;
    my $pkg   = caller(0);
    no strict 'refs';
    *{"$pkg\::pager"} = \&_pager;
    $PAGER_IMPLEMENTATION = shift if @_;
    ( my $pager_implementation_file = "$PAGER_IMPLEMENTATION.pm" ) =~ s{::}{/}g;
    eval { require $pager_implementation_file; };
    _croak "Unable to use $PAGER_IMPLEMENTATION: $@" if $@;
}

sub _pager {
    my $pkg  = shift;
    my @args = qw( entries_per_page current_page pages_per_set mode );
    my $opts = {};
    while ( @_ and not ref $_[0] ) {
        $opts->{ shift @args } = shift;
    }
    my $ref = ref $_[0] eq 'HASH' ? shift : {};
    return bless {
        pkg        => $pkg,
        pager      => undef,
        pager_opts => { %$opts, %$ref, },
      },
      __PACKAGE__;
}

sub AUTOLOAD {
    my $self = shift;
    ( my $method = $AUTOLOAD ) =~ s/.*://;
    if ( ref($self) && $self->{pkg}->can($method) ) {
        my $where = '';
        if ($_[1]) {
             my %args = @_;
             $where = \%args;
        } elsif ($_[0]) {
            $where = shift;
        }
        my $pager_opts = $self->{pager_opts};
        my $offset = $pager_opts->{current_page}
                          ? ( $pager_opts->{current_page} -1 ) * $pager_opts->{entries_per_page} : 0;
        my $limit = $pager_opts->{entries_per_page}
                          ? $pager_opts->{entries_per_page} : 1;
        $self->{pager} = $PAGER_IMPLEMENTATION->new( {
                'total_entries' => $self->{pkg}->count( ref $where eq 'HASH' ? $where->{where} : ''),
                %$pager_opts,
        } );

        if ( ref $where eq 'HASH' ) {
            if ( $offset ) {
                $where->{offset} = $offset;
            }
            $where->{limit} = $limit;
        }

        return ($where) ? $self->{pkg}->$method(%$where) : $self->{pkg}->$method->slice($offset, $offset + $limit -1);

    } elsif ( $PAGER_IMPLEMENTATION->can($method) ) {
        $self->{pager} or _croak("Can't call pager methods before searching");
        return $self->{pager}->$method(@_);
    } else {
        _croak(
            qq(Can't locate object method "$method" via package ) . ref($self)
              || $self );
    }
}

sub DESTROY { }

1;
__END__

=head1 NAME

DBIx::MoCo::Pageset - A flexible pager utility for DBIx::MoCo using Data::Pageset

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  ## DBIx::MoCo class.

  package Blog::User;
  use base qw 'Blog::MoCo';
  
  use DBIx::MoCo::Pageset;
  
  __PACKAGE__->table('user');
  
  
  ## your client code.
  ## you can easily use pager util.
  
  use Blog::User;
  my $pager = Blog::User->pager( {
            entries_per_page => 20,
            current_page     => 1,
            pages_per_set    => 10,
        } );
  my @users = $pager->retrieve_all;


=head1 DESCRIPTION

C<DBIx::MoCo::Pageset> is pager class for C<DBIx::MoCo> using <Data::Pageset>.
This module referred to <Class::DBI::Pageset> and made it.

=head1 EXAMPLE

=head2 client code

  ## your client code.
  ## you can easily use pager util.
  
  use CGI;
  use Template;
  use Blog::User;
  
  my $q     = CGI->new;
  my $pager = Blog::User->pager( {
            entries_per_page => 20,
            current_page     => $q->param('p') || 1,
            pages_per_set    => 10,
        } );
  my $entries = $pager->retrieve_all;
  
  my $template = Template->new;
  $template->process($input, {
      pager  => $pager,
      entries => $entries,
  });

=head2 template (TT)

  [% IF pager.total_entries %][% pager.entries_per_page * ( pager.current_page - 1 ) + 1 %][% ELSE %]0[% END # END IF %]
   - 
  [% pager.entries_per_page * ( pager.current_page - 1 ) + pager.entries_on_this_page %] entries
  ( [% pager.total_entries %] total entries )
  
  [% IF pager.previous_page %]
  <a href="/path/?p=[% pager.previous_page %]">prev</a>
  [% ELSE %]
  prev
  [% END # END IF %]
  
  [% FOREACH num IN pager.pages_in_set %]
  [% IF num == pager.current_page %]<strong>[% num %]</strong>
  [% ELSE %]<a href=/path/?p=[% num %]">[% num %]</a>
  [% END # END IF %]
  [% END # END FOREACH %]
  
  [% IF pager.next_page %]
  <a href="/path/?p=[% pager.next_page %]">prev</a>
  [% ELSE %]
  next
  [% END # END IF %]
  
  [% FOREACH e IN entries %]
  [% e.title | html %]
  [% END # END %]

=head1 SEE ALSO

C<DBIx::MoCo>, C<Data::Pageset>

When I use other O/R Mapper, please use C<Class::DBI::Pageset>, C<DBIx::Class::ResultSet::Data::Pageset>

=head1 BUGS

Please report any bugs or suggestions at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-MoCo-Pageset>

=head1 AUTHOR

syushi matsumoto, C<< <matsumoto at alink.co.jp> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Alink INC. all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

