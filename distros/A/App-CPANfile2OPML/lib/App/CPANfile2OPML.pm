package App::CPANfile2OPML;
use 5.008001;
use strict;
use warnings;

use Module::CPANfile;
use XML::Simple;
use Path::Class;
use File::Path::Expand;
use Cwd;

use constant ALL_PHASES => [qw(configure build test runtime develop)];

our $VERSION = "0.01";

sub new {
    my ($class) = @_;

    bless {}, $class;
}

sub convert_file {
    my ($self, $file, $target_phases) = @_;

    unless ($target_phases && @$target_phases) {
        $target_phases = ALL_PHASES;
    }

    my $title = $self->_title($file, $target_phases);

    my $cpanfile = Module::CPANfile->load($file);

    my @folders;

    for my $phase_name (@$target_phases) {
        my $folder = $self->_phase_to_folder($cpanfile, $phase_name);
        next unless $folder;
        push @folders, $folder;
    }

    my $opml = {
        opml => {
            version => '2.0',
            head => {
                title => [$title],
            },
            body => {
                outline => \@folders,
            },
        },
    };

    my $header = XMLout($opml, RootName => '', XmlDecl => '<?xml version="1.0" encoding="utf-8"?>');
}

sub _title {
    my ($self, $file, $target_phases) = @_;

    my $application = Path::Class::file(Cwd::realpath($file))->parent->basename;

    my $phases = join ', ', @$target_phases;

    "$application/cpanfile($phases)";
}

sub _phase_to_folder {
    my ($self, $cpanfile, $phase_name) = @_;

    my @packages = $self->_collect_packages($cpanfile, $phase_name);
    return unless @packages;

    my @outlines = map {
        $self->_package_name_to_outline($_);
    } @packages;

    return {
        title => $phase_name,
        outline => \@outlines,
    };
}

sub _collect_packages {
    my ($self, $cpanfile, $phase) = @_;

    # TODO: Better access to retrieve CPAN::Meta::Requirements
    my $requirements = $cpanfile->prereqs->{prereqs}->{$phase};
    return unless $requirements;

    my @package_names = $requirements->{requires}->required_modules;

    return @package_names;
}

sub _package_name_to_outline {
    my ($self, $package_name) = @_;

    my $distribution_name = $package_name;
    $distribution_name =~ s/(::)/-/g;
    return {
        title => $package_name,
        htmlUrl => "https://metacpan.org/pod/$package_name",
        xmlUrl => "https://metacpan.org/feed/distribution/$distribution_name",
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

App::CPANfile2OPML - CPANfile to OPML converter

=head1 SYNOPSIS

    use App::CPANfile2OPML;

    my $app = App::CPANfile2OPML->new;
    print $app->convert_file("cpanfile");

=head1 DESCRIPTION

App::CPANfile2OPML generates OPML from CPANfile.

=head1 SEE ALSO

L<cpanfile2opml>

You can subscribe updates of your depending CPAN modules on your favorite feed reader.

=head1 LICENSE

Copyright (C) hitode909.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hitode909 E<lt>hitode909@gmail.comE<gt>

=cut

