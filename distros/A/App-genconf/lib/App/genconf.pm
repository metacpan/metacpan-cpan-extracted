package App::genconf;
BEGIN {
  $App::genconf::AUTHORITY = 'cpan:FFFINKEL';
}
{
  $App::genconf::VERSION = '0.006';
}

#ABSTRACT: The world's simplest config file generator

use strict;
use warnings;

use File::Find;
use Getopt::Long qw/ GetOptions :config bundling /;
use Path::Class qw/ file /;
use Template;
use Try::Tiny;


sub new {
	my ( $class, $inc ) = @_;
	$inc = [@INC] unless ref $inc eq 'ARRAY';
	bless { verbose => 0, }, $class;
}

sub run {
	my ( $self, @args ) = @_;

	local @ARGV = @args;
	GetOptions(
		'v|verbose!'   => sub { ++$self->{verbose} },
		'V|version!'   => \$self->{version},
		'config-dir=s' => \$self->{config_dir},
	) or $self->usage;

	if ( $self->{version} ) {
		$self->puts("genconf (App::genconf) version $App::genconf::VERSION");
		exit 1;
	}

	die 'Must specify template file or directory' unless $ARGV[0];

	if ( -f $ARGV[0] ) {
		$self->_generate_config( $ARGV[0] );
	}
	else {
		my @files;
		find( sub { push @files, $File::Find::name unless -d; }, $ARGV[0] );
		for my $file (@files) {
			$self->_generate_config($file);
		}
	}

}

sub usage {
	my $self = shift;
	$self->puts(<< 'USAGE');
Usage:
  genconf [options] template|dir

  options:
    -v,--verbose                  Turns on chatty output
    --config-dir                  Specify config file directory, default .
USAGE

	exit 1;
}

sub _generate_config {
	my $self     = shift;
	my $template = shift;

	my $template_file = file($template);
	my $filename      = $template_file->basename;

	my $config =
	  $self->{config_dir}
	  ? "$self->{config_dir}/$filename"
	  : $filename;

	my $tt = Template->new( { ABSOLUTE => 1, } ) || die "$Template::ERROR\n";
	$tt->process( $template, \%ENV, $config ) || die $tt->error();

	return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::genconf - The world's simplest config file generator

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  # Create a config template
  vi templates/config/myapp_local.yml

    app_name: [% APP_NAME %]
    is_production: [% IS_PRODUCTION %]

  # Add the required rontment variables
  export APP_NAME=LOLCatter
  export IS_PRODUCTION=0

  # Run genconfig
  genconfig templates/config

=head1 DESCRIPTION

Genconf is a very simple config file generation tool.  Source control config
templates; use a simple command to genrate|update whatever environment's config
files.

=head1 NAME

App::genconf - The world's simplest config file generator

=head1 TEMPLATE TIPS

  # Make config values required by using the assert plugin, which causes the
  # template processor to throw an error if undef values are returned:
  [% USE assert %]
  app_name: [% env.assert.APP_NAME %]

  # Cut out optional config sections with a simple IF:
  [% IF DB_CONN_STRING and DB_USERNAME and DB_PASSWORD %]
  db_connection_info:
    - [% DB_CONN_STRING %]
    - [% DB_USERNAME %]
    - [% DB_PASSWORD %]
  [% END %]

  # Use the TAGS directive if you need [% in your config:
  [% TAGS [- -] %]
  [%User]
  name = [- USER_NAME -]
  password = [- USER_PASSWORD -]

How it helps:

=over

=item

Store all configs in version control

=item

Never commit passwords to version control

=item

Keep team members' dev config schemas in sync

=back

=head1 ARGUMENTS

=head2 --config-dir

Specify the config file output directory

=head1 AUTHOR

Matt Finkel <fffinkel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Matt Finkel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
