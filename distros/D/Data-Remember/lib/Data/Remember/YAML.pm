use strict;
use warnings;

package Data::Remember::YAML;
{
  $Data::Remember::YAML::VERSION = '0.140490';
}
use base qw/ Data::Remember::Memory /;
# ABSTRACT: a frozen memory brain plugin for Data::Remember

use Carp;
use YAML::Syck ();


sub new {
    my $class = shift;
    my %args  = @_;

    croak 'You must specify a "file" to load the data from.'
        unless $args{file};

    my $brain;
    if (-f $args{file}) {
        $brain = YAML::Syck::LoadFile($args{file});
    }
    else {
        carp qq{Empty brain, "$args{file}" is not a file.};
        $brain = {};
    }

    bless { 
        brain => $brain,
        file  => $args{file},
    }, $class;
}


sub load {
    my $self = shift;
    my $file = shift || $self->{file};

    $self->{brain} = YAML::Syck::LoadFile($file);
}


sub dump {
    my $self = shift;
    my $file = shift || $self->{file};

    YAML::Syck::DumpFile($file, $self->{brain});
}


1;

__END__

=pod

=head1 NAME

Data::Remember::YAML - a frozen memory brain plugin for Data::Remember

=head1 VERSION

version 0.140490

=head1 SYNOPSIS

  use Data::Remember YAML => file => 'brain.yml';

  my $blah = recall 'something';

=head1 DESCRIPTION

This brain plugin uses L<YAML::Syck> to load and store information for L<Data::Remember>. To use this module you must specify the "file" argument to tell the module where to load the data from.

=head1 METHODS

=head2 new file => FILENAME

Pass the name of the file to use to load the data from. The "file" argument is required.

=head2 load FILENAME

Reloads the information from the YAML file or loads information from a different YAML file. The FILENAME argument is optional, if not given the file loaded will be the one that was given when the brain was originally created.

=head2 dump FILENAME

Dumps the informaiton from the configuration file or saves information into another file. The FILENAME argument is optional, if not given the file saved to will be the one that was given when the brain was originally created.

=head1 SEE ALSO

L<Data::Remember>, L<Data::Remember::Memory>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
