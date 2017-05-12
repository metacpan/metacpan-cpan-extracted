package Class::DBI::Plugin::NoCache;
use strict;
use vars qw/$VERSION/;
$VERSION = 0.03;
sub import {
    my $class = shift;
    my $pkg   = caller(0);
    unless($pkg->isa('Class::DBI')){
        require Carp;
        Carp::croak("This is a plugin for Class::DBI.");
    }
    $pkg->mk_classdata('nocache');
    no strict 'refs';
    my $super = $pkg->can('_init');
    *{$pkg."::_init"} = sub {
        my $caller = shift;
        local $Class::DBI::Weaken_Is_Available = not $caller->nocache;
        return $super->($caller, @_);
    };
}
1;
__END__

=head1 NAME

Class::DBI::Plugin::NoCache - CDBI record caching controller

=head1 SYNOPSIS

  package CD;
  use base qw(Class::DBI);
  use Class::DBI::Plugin::NoCache;
  
  __PACKAGE__->set_db(...);


  package Music::CD;
  use base qw(CD);

  __PACKAGE__->nocache(1);
  __PACKAGE__->columns(Primary => qw/id/);
  __PACKAGE__->columns(Essential => qw/artist title/);

=head1 DESCRIPTION

When you get or create records with CDBI, all the records will be cached.
However, there is a problem that a process of CDBI application can't be notified
about the change of the records by other processes.

So, maybe there are times when you want to stop caching especially in mod_perl or FastCGI environment.

This module allows you to stop CDBI's caching.

This is temporary solution, chaching is essential of applications.
Better to controll caches well.

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::Sweet>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Lyo Kato.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

