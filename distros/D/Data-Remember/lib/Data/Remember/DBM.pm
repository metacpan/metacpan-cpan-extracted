use strict;
use warnings;

package Data::Remember::DBM;
{
  $Data::Remember::DBM::VERSION = '0.140490';
}
use base qw/ Data::Remember::Memory /;
# ABSTRACT: a long-term memory brain plugin for Data::Remember

use Carp;
use DBM::Deep;


sub new {
    my $class = shift;
    my %args  = @_;

    croak 'You must specify a "file" to store the data in.'
        unless $args{file};

    bless { brain => DBM::Deep->new( $args{file} ) }, $class;
}


sub dbm {
    my $self = shift;
    return $self->{brain};
}


1;

__END__

=pod

=head1 NAME

Data::Remember::DBM - a long-term memory brain plugin for Data::Remember

=head1 VERSION

version 0.140490

=head1 SYNOPSIS

  use Data::Remember DBM => file => 'brain.db';

  remember something => 'what?';

=head1 DESCRIPTION

This is a brain plugin module for L<Data::Memory> that persists everything stored using L<DBM::Deep>. To use this module you must specify the "file" argument to tell the module where to store the files.

=head1 METHODS

=head2 new file => FILENAME

Pass the name of the file to use to store the persistent data in. The "file" argument is required.

=head2 dbm

If you need to do any locking or additional work with L<DBM::Deep> directly, use this method to get a reference to the current instance.

  my $dbm = brain->dbm;

=head1 SEE ALSO

L<Data::Remember>, L<Data::Remember::Memory>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
