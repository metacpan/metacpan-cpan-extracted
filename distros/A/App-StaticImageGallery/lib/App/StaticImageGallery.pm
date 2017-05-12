package App::StaticImageGallery;
BEGIN {
  $App::StaticImageGallery::VERSION = '0.002';
}

use App::StaticImageGallery::Dir;
use Path::Class ();
use Getopt::Lucid qw( :all );
use Pod::Usage;
use File::Path ();

sub new_with_options {
    my $class = shift;

    my @specs = (
        Counter("verbose|v"),
        Counter("quiet|q"),
        Switch("recursive")->default( 1 ),
        Param("style|s")->default("Simple"),
    );

    my $cb = sub {
        my ($self) = @_;
        print "TODO Command ",$self->cmd_name,"\n";
    };

    my $self  = {
        _opt      => Getopt::Lucid->getopt(\@specs),
        _cmd_name => shift @ARGV,
        _work_dir => shift @ARGV || '.',
        _cmd_dipatcher => {
            build           => sub { shift->cmd_build(@_) },
            help            => sub {
                my $self = shift;
                pod2usage(
                    -input => __FILE__,
                    -verbose => 99,
                    -exitval => 0,
                    -sections => ['NAME','VERSION','SYNOPSIS','COMMANDS','OPTIONS']
                );

            },
            imager_formats  => sub {
                my $self = shift;
                require Imager;
                $self->msg("Supported image formats: " . join(', ',keys %Imager::formats) . '.');
            },
            clean           => sub { shift->cmd_clean(@_); },
            rebuild         => sub {
                my $self = shift;
                $self->cmd_clean(@_);
                $self->cmd_build(@_);
            },
            init            => $cb,
            list_styles     => $cb,
        }
    };
    bless $self, $class;

    $self->msg_verbose(2,"Work dir: %s", $self->{_work_dir});
    return $self;
}

sub opt { shift->{_opt} };

sub config {
    return {
        data_dir_name => '.StaticImageGallery',
    }
}

sub cmd_name { shift->{_cmd_name}; };

sub _disptach_cmd {
    my $self = shift;
    if (defined $self->{_cmd_dipatcher}->{ $self->cmd_name } ){
        $self->{_cmd_dipatcher}->{ $self->cmd_name  }($self);
    }else{
        die sprintf("Command '%s' not found.",$self->cmd_name);
    }
}

sub cmd_build {
    my ($self) = @_;

    my $dir = App::StaticImageGallery::Dir->new(
        ctx => $self,
        work_dir => Path::Class::dir( $self->{_work_dir} ),
    );

    $dir->write_index();
    return;
}

sub cmd_clean {
    my ($self) = @_;

    my $dir = App::StaticImageGallery::Dir->new(
        ctx => $self,
        work_dir => Path::Class::dir( $self->{_work_dir} ),
    );

    return $dir->clean_work_dir();
}

sub run {
    my ($self) = @_;
    $self->_disptach_cmd();
}

sub msg_verbose {
    my $self = shift;
    my $level = shift;
    my $format = shift;
    return if $self->opt->get_verbose() == 0;

    if ( $self->opt->get_verbose() >= $level ){
        printf '[sig:VERBOSE:%2s] ' . $format . "\n" ,$level,@_;
    }
    return;
}

sub msg {
    my $self = shift;
    my $format = shift;
    return if $self->opt->get_quiet() > 0;
    printf '[sig] ' . $format . "\n" ,@_;
    return;
}

sub msg_warning {
    my $self = shift;
    my $format = shift;
    printf STDERR $format . "\n" ,@_;
    return;
}

sub msg_error {
    my $self = shift;
    my $format = shift;
    printf STDERR $format . "\n" ,@_;
    return;
}

1;    # End of App::StaticImageGallery
__END__
=head1 NAME

App::StaticImageGallery - Static Image Gallery

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    ./bin/sig [command] [options]

=head1 COMMANDS

=head2 build [dir]

Create image gallery

Dir: Working directory, direcotry with the images. 
Write html pages and thumbnails into this directory.


=head2 imager_formats

List all available image formats

=head2 init

Initila App-StaticImageGallery

=head2 list_styles

List all available styles and there source

=head2 clean

Remove all image gallery files

=head2 rebuild

Run command clean and build.

=head1 OPTIONS

=head2 B<--style|-s>

=over 4

=item Default: Simple

=back

Set the style/theme.

=head2 B<--help|-h>

Print a brief help message and exits.

=head2 B<-v>

Verbose mode, more v more output...

=head2 B<--quiet|-q>

Quite mode

=head2 B<--no-recursive>

Disabled recursiv mode

=head1 METHODS

=over 4

=item new_with_options

=item config

Returns the config hashref, at the moment the configuration is hardcode in StaticImageGallery.pm

=item msg

If not in quite mode, print message to STDOUT.

=item msg_error

Print message at any time to STDERR.

=item msg_verbose

=item msg_warning

Print message at any time to STDERR.

=item opt

Returns the L<Getopt::Lucid> object.

=item run

=item cmd_build

Command build

=item cmd_clean

Command clean

=item cmd_name

Name of the current command

=back

=head1 TODO

=over 4

=item * Documentation

=item * Sourcecode cleanup

=item * Write Dispatcher
    
    App::StaticImageGallery::Style::Source::Dispatcher

=item * App::StaticImageGallery::Image line: 31, errorhandling

=item * Test unsupported format

=item * Added config file support ( App::StaticImageGallery->config )

=item * Write App::StaticImageGallery::Style::Source::FromDir

=item * Add config file ~/.sig/config.ini

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Robert Bohne.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Robert Bohne, C<< <rbo at cpan.org> >>