package Class::DBI::Pageset;

###########################################################################
# Class::DBI::Pageset
# Mark Grimes
# $Id: NAMESPACE.pm,v 1.3 2006/11/29 02:40:22 mgrimes Exp $
#
# A flexible pager utility for Class::DBI
# Copyright (c) 2008 Mark Grimes (mgrimes@cpan.org).
# All rights reserved. This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.
#
# Heavily inspired by (read: stolen from) Class::DBI::Pager and
# DBIx::Class::ResultSet::Data::Pageset. Thanks!
#
###########################################################################

use strict;
use warnings;

our $VERSION = '0.14';
our $AUTOLOAD;

use Class::DBI 0.90;
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
        my $iter = $self->{pkg}->$method(@_);
        UNIVERSAL::isa( $iter, 'Class::DBI::Iterator' )
          or _croak("$method doesn't return Class::DBI::Itertor");
        my $pager_opts = $self->{pager_opts};
        my $pager = $self->{pager} = $PAGER_IMPLEMENTATION->new( {
                total_entries => $iter->count,
                %$pager_opts,
        } );
        return $iter->slice( $pager->first - 1, $pager->last - 1 );
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

Class::DBI::Pageset - A flexible pager utility for Class::DBI using Data::Pageset

=head1 SYNOPSIS

  package CD;
  use base qw(Class::DBI);
  use Class::DBI::Pageset;        # just use it
  __PACKAGE__->set_db(...);

  # then, in client code!
  package main;
  use CD;
  my $pager = CD->pager( {
            entries_per_page => 20,
            current_page     => 1,
            pages_per_set    => 10,
        } );
  my @disks = $pager->retrieve_all;

=head1 DESCRIPTION

C<Class::DBI::Pageset> is a plugin for C<Class::DBI> that integrates 
C<Data::Pageset> into C<Class::DBI> with minimal fuss. This enables you
to search via C<Class::DBI> and grouping results into pages and page sets.

This module is very similar to Tatsuhiko Miyagawa's very nice
C<Class::DBI::Pager> module, but uses C<Data::Pageset> (or any module that
inherits from C<Data::Pageset>, such as C<Data::Pageset::Render>) to create
the pager. C<Data::Pageset> provides a more flexible pager, which is better
suited to searches that return many pages. This is not necessarily very
efficient (see C<NOTE> below for more).

=head1 EXAMPLE

  # Controller: (MVC's C)
  my $query    = CGI->new;
  my $template = Template->new;

  my $pager    = Film->pager({ 
    entries_per_page => 20,
    current_page     => $query->param('page') || 1,
    pages_per_set    => 5, 
  });
  my $movies   = $pager->retrieve_all;
  $template->process($input, {
      movies => $movies,
      pager  => $pager,
  });

  # View: (MVC's V)
  Matched [% pager.total_entries %] items.

  [% WHILE (movie = movies.next) %]
  Title: [% movie.title | html %]
  [% END %]

  ### navigation like:   ... 5 [6] 7 8 9 ...
  [% IF pager.previous_set %] 
    <a href="display?page=[% pager.previous_set %]">...</a>
  [% END %]
  [% FOREACH num = [ pager.pages_in_set ] %]
  [% IF num == pager.current_page %] [[% num %]]
  [% ELSE %]<a href="display?page=[% num %]">[% num %]</a>[% END %]
  [% END %]
  [% IF pager.next_set %]
    <a href="display?page=[% pager.next_set %]">...</a>
  [% END %]

To use one of the modules that inherit from C<Data::Pageset> (such as 
C<Data::Pageset::Render>) just include the module name as part of the C<use>
statement.

    use Class::DBI::Pageset qw(Data::Pageset::Render);
    ## Then in your code you can use
    $pager->html( '<a href="index?page=%s">%a</a>' );

=head1 METHODS

=over 4

=item pager()

    my $pager = Film->pager({ 
        entries_per_page => 20,
        current_page     => $query->param('page') || 1,
        pages_per_set    => 5, 
        mode             => 'slide',
    });

This is the constructor for the pager. See C<Data::Pageset> for more on the
parameters. The C<$pager> object can then be used as a normal C<Class::DBI>
object for searching.

=item total_entries()

=item entries_per_page()

=item current_page()

=item entries_on_this_page()

=item first_page()

=item last_page()

=item first()

=item last()

=item previous_page()

=item next_page()

=item pages_in_navigatio()

=item pages_per_set()

=item previous_set()

=item next_set()

=item pages_in_set()

See C<Data::Pageset>.

=back

=head1 NOTE

This modules internally retrieves itertors, then creates Data::Page object
for paging utility. Using SQL clauses LIMIT and/or OFFSET with DBIx::Pager
might be more memory efficient. As this module is geared to searches that
return many pages of results, it maybe more prone to inefficiencies than
C<Class::DBI::Pager>.

I had originally wanted to patch C<Class::DBI::Pager> to use different pagers,
ie, C<Data::Page>, C<Data::Pageset>, or C<Data::Pageset::Render>, but the 
constructors for C<Data::Page> and C<Data::Pageset> are incompatible and 
jamming them together didn't seem like a good fix.

=head1 SEE ALSO

C<Class::DBI>, C<Data::Pageset>

Or for alternatives: C<Class::DBI::Pager>, C<DBIx::Class>,
C<DBIx::Class::ResultSet::Data::Pageset>

=head1 BUGS

Please report any bugs or suggestions at 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-DBI-Pageset>

=head1 AUTHOR

Mark Grimes E<lt>mgrimes@cpan.orgE<gt>

Most of this code was shamelessly taken from the very nice
C<Class::DBI::Pager> by Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by mgrimes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
