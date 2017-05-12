package App::envfile;

use strict;
use warnings;
use 5.008_001;
use Carp ();

our $VERSION = '0.07';

our $EXTENTIONS_MAP = {
    pl   => 'Perl',
    perl => 'Perl',
    js   => 'JSON',
    json => 'JSON',
    yml  => 'YAML',
    yaml => 'YAML',
};

sub new {
    my $class = shift;
    bless {}, $class;
}

sub run_with_env {
    my ($self, $env, $commands) = @_;
    local %ENV = %ENV;
    for my $key (keys %$env) {
        $ENV{$key} = $env->{$key};
    }
    exec(@$commands);
}

sub parse_envfile {
    my ($self, $file) = @_;
    Carp::croak "Usage: $self->parse_envfile(\$file)" unless defined $file;

    my $env = {};
    return $env if $env = $self->_try_any_config_file($file);

    open my $fh, '<', $file or Carp::croak "$file: $!";
    while (defined (my $line = readline $fh)) {
        chomp $line;
        next if index($line, '#') == 0;
        next if $line =~ /^\s*$/;
        my ($key, $value) = $self->_parse_line($line);
        $env->{$key} = $value;
    }
    close $fh;

    return $env;
}

sub _try_any_config_file {
    my ($self, $file) = @_;

    my ($ext) = $file =~ /\.(\w+)$/;
    if (my $type = $EXTENTIONS_MAP->{lc($ext || '')}) {
        my $env;
        if ($type eq 'Perl') {
            $env = do "$file";
            die $@ if $@;
        }
        else {
            require Data::Encoder;
            $env = Data::Encoder->load($type)->decode($self->_slurp($file));
        }
        die "$file: Should be return HASHREF\n" unless ref $env eq 'HASH';
        return $env;
    }

    return;
}

sub _slurp {
    my ($self, $file) = @_;
    my $data = do {
        local $\;
        open my $fh, '<', $file or die "$file: $!\n";
        <$fh>;
    };
    return $data;
}

sub _parse_line {
    my ($self, $line) = @_;
    my ($key, $value) = map { my $str = $_; $str =~ s/^\s+|\s+$//g; $str } split '=', $line, 2;
    return $key, $value;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

App::envfile - runs another program with environment modified according to envfile

=head1 SYNOPSIS

  $ cat > foo.env
  FOO=bar
  HOGE=fuga
  $ envfile foo.env perl -le 'print "$ENV{FOO}, $ENV{HOGE}"'
  bar, fuga

like

  $ env FOO=bar HOGE=fuga perl -le 'print "$ENV{FOO}, $ENV{HOGE}"'

=head1 DESCRIPTION

App::envfile is sets environment from file.

envfile inspired djb's envdir program.

=head1 METHODS

=head2 new()

Create App::envfile instance.

  my $envf = App::envfile->new();

=head2 run_with_env(\%env, \@commands)

Runs another program with environment modified according to C<< \%env >>.

  $envf->run_with_env(\%env, \@commands);

=head2 parse_envfile($envfile)

Parse the C<< envfile >>. Returned value is HASHREF.

  my $env = $envf->parse_envfile($envfile);

Supported file format are:

  KEY=VALUE
  # comment
  KEY2=VALUE
  ...

Or more supported C<< Perl >>, C<< JSON >> and C<< YAML >> format.
The file format is determined by the extension type. extensions map are:

  pl   => Perl
  perl => Perl
  js   => JSON
  json => JSON
  yml  => YAML
  yaml => YAML

If this list does not match then considers that file is envfile.

Also, if you use C<< YAML >> and C<< JSON >>, L<< Data::Encoder >> and L<< YAML >> or L<< JSON >> module is required.

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 THANKS TO

tokuhirom

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
