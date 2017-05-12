use strict;
use warnings;

package Code::Statistics::Collector;
{
  $Code::Statistics::Collector::VERSION = '1.112980';
}

# ABSTRACT: collects statistics and dumps them to json

use 5.006_003;

use Moose;
use MooseX::HasDefaults::RO;
use Code::Statistics::MooseTypes;
use MooseX::SlurpyConstructor 1.1;
use Code::Statistics::Metric;
use Code::Statistics::Target;

use File::Find::Rule::Perl;
use Code::Statistics::File;
use JSON 'to_json';
use File::Slurp 'write_file';
use Term::ProgressBar::Simple;
use File::Find::Rule;

has no_dump => ( isa => 'Bool' );

has dirs => (
    isa    => 'CS::InputList',
    coerce => 1,
    default => sub { ['.'] },
);

has files => (
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        return $_[0]->_prepare_files;
    },
);

has targets => (
    isa     => 'CS::InputList',
    coerce  => 1,
    default => sub { $_[0]->_get_all_submodules_for('Target') },
);

has metrics => (
    isa     => 'CS::InputList',
    coerce  => 1,
    default => sub { $_[0]->_get_all_submodules_for('Metric') },
);

has progress_bar => (
    isa     => 'Term::ProgressBar::Simple',
    lazy    => 1,
    default => sub {
        my $params = { name => 'Files', ETA => 'linear', max_update_rate => '0.1' };
        $params->{count} = @{ $_[0]->files };
        return Term::ProgressBar::Simple->new( $params );
    },
);

has command_args => (
    is      => 'ro',
    slurpy  => 1,
    default => sub { {} },
);


sub collect {
    my ( $self ) = @_;

    $_->analyze for @{ $self->files };

    my $json = $self->_measurements_as_json;
    $self->_dump_file_measurements( $json );

    return $json;
}

sub _find_files {
    my ( $self ) = @_;
    my @files = (
        File::Find::Rule::Perl->perl_file->in( @{ $self->dirs } ),
        File::Find::Rule->file->name( '*.cgi' )->in( @{ $self->dirs } ),
    );
    @files = sort { lc $a cmp lc $b } @files;
    return @files;
}

sub _prepare_files {
    my ( $self ) = @_;
    my @files = $self->_find_files;
    @files = map $self->_prepare_file( $_ ), @files;
    return \@files;
}

sub _prepare_file {
    my ( $self, $path ) = @_;

    my %params = (
        path      => $path,
        original_path => $path,
        targets   => $self->targets,
        metrics   => $self->metrics,
        progress => sub { $self->progress_bar->increment },
    );

    return Code::Statistics::File->new( %params, %{$self->command_args} );
}

sub _dump_file_measurements {
    my ( $self, $text ) = @_;
    return if $self->no_dump;

    write_file( 'codestat.out', $text );

    return $self;
}

sub _measurements_as_json {
    my ( $self ) = @_;

    my @files = map $self->_strip_file( $_ ), @{ $self->files };
    my @ignored_files = $self->_find_ignored_files( @{ $self->files } );

    my $measurements = {
        files => \@files,
        targets => $self->targets,
        metrics => $self->metrics,
        ignored_files => \@ignored_files
    };

    my $json = to_json( $measurements, { pretty => 1, canonical => 1 } );

    return $json;
}

sub _find_ignored_files {
    my ( $self, @files ) = @_;

    my %present_files = map { $_->{original_path} => 1 } @files;

    my @all_files = File::Find::Rule->file->in( @{ $self->dirs } );
    @all_files = grep { !$present_files{$_} } @all_files;
    my $useless_stuff = qr{
        (^|/)
            (
                [.]git   |   [.]svn   |   cover_db   |   [.]build   |   nytprof   |
                blib
            )
        /
    }x;
    @all_files = grep { $_ !~ $useless_stuff } @all_files; # filter out files we most certainly do not care about

    return @all_files;
}


sub _strip_file {
    my ( $self, $file ) = @_;
    my %stripped_file = map { $_ => $file->{$_} } qw( path measurements );
    return \%stripped_file;
}

sub _get_all_submodules_for {
    my ( $self, $type ) = @_;
    my $class = "Code::Statistics::$type";
    my @list = sort $class->all;

    $_ =~ s/$class\::// for @list;

    my $all = join ';', @list;

    return $all;
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::Collector - collects statistics and dumps them to json

=head1 VERSION

version 1.112980

=head2 collect
    Locates files to collect statistics on, collects them and dumps them to
    JSON.

=head2 _strip_file
    Cuts down a file hash to have only the keys we actually want to dump to the
    json file.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

