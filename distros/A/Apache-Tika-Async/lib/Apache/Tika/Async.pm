package Apache::Tika::Async;
use strict;
use Moo 2;
use JSON::XS qw(decode_json);
use File::Temp 'tempfile';

our $VERSION = '0.11';

=head1 NAME

Apache::Tika::Async - connect to Apache Tika

=head1 SYNOPSIS

  use Apache::Tika::Async;

  my $tika= Apache::Tika::Async->new;

  my $fn= shift;

  use Data::Dumper;
  my $info = $tika->get_all( $fn );
  print Dumper $info->meta($fn);
  print $info->content($fn);
  # <html><body>...
  print $info->meta->{"meta:language"};
  # en

=head1 ACCESSORS

=cut

=head2 B<jarfile>

  jarfile => '/opt/tika/tika-standard-2.9.9.jar',

Sets the Tika Jarfile to be used. The default is to look
in the directory C<jar/> below the current directory.

=cut

has 'jarfile' => (
    is => 'rw',
    #isa => 'Str',
# tika-server-1.24.1.jar
# tika-server-standard-2.3.0.jar

    default => sub {
        $ENV{PERL_APACHE_TIKA_PATH} ||
        __PACKAGE__->best_jar_file(
              glob 'jar/tika-server-*.jar'
        );
    },
);

=head2 B<tika_args>

  tika_args => [],

Additional Tika command line options.

=cut


has tika_args => (
    is => 'rw',
    #isa => 'Array',
    default => sub { [ ] },
);

=head2 B<java>

  java => '/opt/openjdk-11-jre/bin/java',

Sets the Java executable to be used.

=cut

has java => (
    is => 'rw',
    #isa => 'Str',
    default => 'java',
);

=head2 B<java_args>

  java_args => [],

Sets the Java options to be used.

=cut

has java_args => (
    is => 'rw',
    #isa => 'Array',
    builder => sub { [
        # So that Tika can re-read some problematic PDF files better
        '-Dorg.apache.pdfbox.baseParser.pushBackSize=1000000'
    ] },
);

sub _tika_config_xml {
    my( $self, %entries ) = @_;
    return join '',
'<?xml version="1.0" encoding="UTF-8"?>',
'<properties>',
'<!-- <parsers etc.../> -->',
'<server>',
    '<params>',
    (map { join '', "<$_>" => $entries{ $_ } => "</$_>" } sort keys %entries),
    '</params>',
'</server>',
'</properties>',
}

sub tika_config {
    my( $self, %entries ) = @_;
    return $self->_tika_config_xml(
        logLevel => $self->loglevel,
        %entries
    );
}

sub tika_config_temp_file {
    my( $self, %entries ) = @_;

    my( $fh, $name ) = tempfile();
    binmode $fh;
    print {$fh} $self->tika_config(%entries);
    close $fh;

    return $name;
}

sub best_jar_file {
    my( $package, @files ) = @_;
    # Do a natural sort on the dot-version
    (sort { my $ad; $a =~ /\bserver-(?:standard-|)(\d+)\.(\d+)/ and $ad=sprintf '%02d.%04d', $1, $2;
            my $bd; $b =~ /\bserver-(?:standard-|)(\d+)\.(\d+)/ and $bd=sprintf '%02d.%04d', $1, $2;
                $bd <=> $ad
          } @files)[0]
}

sub cmdline {
    my( $self )= @_;
    $self->java,
    @{$self->java_args},
    '-jar',
    $self->jarfile,
    '--config', $self->tika_config_temp_file,
    @{$self->tika_args},
};

sub fetch {
    my( $self, %options )= @_;
    my @cmd= $self->cmdline;
    push @cmd, $options{ type };
    push @cmd, $options{ filename };
    @cmd= map { qq{"$_"} } @cmd;
    #die "Fetching from local process is currently disabled";
    #warn "[@cmd]";
    '' . readpipe(@cmd)
}

sub decode_csv {
    my( $self, $line )= @_;
    $line =~ m!"([^"]+)"!g;
}

sub get_meta {
    my( $self, $file )= @_;
    #return decode_json($self->fetch( filename => $file, type => 'meta' ));
    # Hacky CSV-to-hash decode :-/
    return $self->fetch( filename => $file, type => 'meta' )->meta->get;
};

sub get_text {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'text' )->get;
};

sub get_test {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'test' )->get;
};

sub get_all {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'all' )->get;
};

sub get_language {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'language' )->get;
};

# ->detect_stream wants not a file but the input bytes
# sub detect_stream {
#     my( $self, $file )= @_;
#     return $self->fetch( filename => $file, type => 'all' )->get;
# };

# __PACKAGE__->meta->make_immutable;

1;

=head1 ENVIRONMENT

To specify the Tika jar file from the outside, you can set the
C<PERL_APACHE_TIKA_PATH> environment variable.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Apache-Tika-Async>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Apache-Tika-Async>
or via mail to L<apache-tika-async-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
