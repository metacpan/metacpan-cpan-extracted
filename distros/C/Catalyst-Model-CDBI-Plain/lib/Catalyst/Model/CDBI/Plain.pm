package Catalyst::Model::CDBI::Plain;

use strict;
our $VERSION = '0.02';
use base qw[Class::DBI Catalyst::Base];

sub new {
    my ( $class, $c ) = @_;
    return Catalyst::Base::new( $class, $c );
}

1;

__END__

=head1 NAME

Catalyst::Model::CDBI::Plain - A Plain base class for Class::DBI models

=head1 SYNOPSIS

    # set up your CDBI classes within Catalyst: base class
    package Music::Model::DBI;
    use base 'Catalyst::Model::CDBI::Plain';
    __PACKAGE__->connection('dbi:mysql:music', 'user', 'pw');

    # One class, inherits from base, sets up relationships
    package Music::Model::Artist;
    use base 'Music::Model::DBI';
    __PACKAGE__->table('artist');
    __PACKAGE__->columns(All => qw/artistid name/);
    __PACKAGE__->has_many(cds => 'Music::Model::CD');

    # etc.

    # OR

    # use existing CDBI classes within Catalyst:
    package MyApp::Model::Artist; # a Catalyst class
    use base qw[Catalyst::Model::CDBI::Plain Some::Other::Artist];
    1; # That's it--Some::Other::Artist is in Catalyst as MyApp::Model::Artist

    # OR

    package MyApp::Model::Library;
    use base qw[MyApp::Model::DBI Class::DBI::mysql]; # add MySQL-specific methods
    __PACKAGE__->set_up_table('library'); # from CDBI::mysql

=head1 DESCRIPTION

C<Catalyst::Model::CDBI::Plain> is a Model class for Catalyst to be used
with user-specified L<Class::DBI> classes. It does not automatically set
anything up or create relationships; this is left to the user. This
module can be used with existing C<Class::DBI> classes, so that they can
be used with Catalyst, or as a way of writing CDBI-based Model classes
within Catalyst.

=head1 AUTHOR

Jesse Sheidlower C<E<lt>jester@panix.comE<gt>>

Christian Hansen C<E<lt>ch@ngmedia.comE<gt>>

=head1 THANKS TO

Marcus Ramberg, Sebastian Riedel

=head1 SUPPORT

IRC
  #catalyst on irc.perl.org

Mailing-Lists:
  http://lists.rawmode.org/mailman/listinfo/catalyst
  http://lists.rawmode.org/mailman/listinfo/catalyst-dev

=head1 TODO
  Real tests

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catalyst>

L<Class::DBI>

L<Catalyst::Model::CDBI>

=cut
