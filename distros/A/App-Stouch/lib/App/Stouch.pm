package App::Stouch;
our $VERSION = '0.01';
use 5.016;

use App::Stouch::Template qw(render_file render_directory);

use File::Spec;
use Getopt::Long;

my $PRGNAM = 'stouch';
my $PRGVER = $VERSION;

my $HELP_MSG = <<HERE;
$PRGNAM - $PRGVER
Usage: $0 [options] file ...

Options:
  -T <template>  Template to use for file(s)
  -t <dir>       Template directory
  -p <param>     Template text substitution parameters
  -q             Quiet; disable informative messages
  -h             Print help message and exit
  -v             Print version/copyright info and exit
HERE

my $VER_MSG = <<HERE;
$PRGNAM - $PRGVER

Copyright 2024, Samuel Young

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.
HERE

sub parse_template_param {

	my $str = shift;

	my $param = {};

	foreach my $p (split ',', $str) {

		my ($key, $val) = split '=>', $p, 2;

		$key =~ s/^\s+|\s+$//g;
		$val =~ s/^\s+|\s+$//g;

		if ($key !~ /^\w+$/) {
			die "Template parameter field cannot contain non-alphanumeric character";
		}

		unless ($val) {
			die "Template parameter cannot be empty value";
		}

		$param->{$key} = $val;

	}

	unless ($param) {
		die "Found no template parameters in given string";
	}


	return $param;

}

sub init {

	my $class = shift;

	my $self = {
		Template      => undef,
		TemplateDir   => $ENV{STOUCH_TEMPLATES},
		TemplateParam => {},
		Files         => [],
		Quiet         => 0,
	};

	my $paramstr = '';

	Getopt::Long::config('bundling');
	GetOptions(
		'T=s' => \$self->{Template},
		't=s' => \$self->{TemplateDir},
		'p=s' => \$paramstr,
		'q'   => \$self->{Quiet},
		'h'   => sub { print $HELP_MSG; exit 0; },
		'v'   => sub { print $VER_MSG;  exit 0; },
	) or die $HELP_MSG;

	unless (@ARGV) {
		die $HELP_MSG;
	}

	$self->{Files} = \@ARGV;

	unless (defined $self->{TemplateDir}) {
		die "Template directory must be specified by either the -t option or " .
		    "STOUCH_TEMPLATES environment variable";
	}

	unless (-d $self->{TemplateDir}) {
		die "$self->{TemplateDir} is not a directory";
	}

	if ($paramstr) {
		$self->{TemplateParam} = parse_template_param($paramstr);
	}

	return bless $self, $class;

}

sub run {

	my $self = shift;

	foreach my $f (@{$self->{Files}}) {

		my $template = '';
		if (defined $self->{Template}) {
			$template = $self->{Template};
		} else {
			($template) = $f =~ /\.([^.]+)$/;
			die "$f has no file suffix" unless $template;
		}

		my $tpath = File::Spec->catfile($self->{TemplateDir}, "$template.template");

		my @created;

		if (-d $tpath) {
			@created = render_directory($tpath, $f, $self->{TemplateParam});
			say "Created new $template directory:" unless $self->{Quiet};
		} elsif (-f $tpath or -l $tpath) {
			@created = render_file($tpath, $f, $self->{TemplateParam});
			say "Created new $template file:" unless $self->{Quiet};
		} else {
			die "No template for $template files exists";
		}

		unless ($self->{Quiet}) {
			foreach my $c (@created) {
				say "  $c";
			}
		}

	}

}

sub get {

	my $self = shift;
	my $get  = shift;

	return undef if $get =~ /^_/;

	return $self->{$get};

}

1;

=head1 NAME

App::Stouch - Simple template file creator

=head1 SYNOPSIS

  use App::Stouch;

  my $stouch = App::Stouch->init();
  $stouch->run();

=head1 DESCRIPTION

App::Stouch is backend module for the L<stouch> program. You should probably be
reading its documentation instead of than this.

App::Stouch is designed solely for L<stouch>'s use and should not be used by
any other program/script.

=head1 METHODS

=over 4

=item $stouch = App::Stouch->init()

Processes @ARGV and returns a blessed App::Stouch object. Consult the
documentation for L<stouch> for a list of supported options.

=item $stouch->run()

Runs L<stouch>.

=item $stouch->get($get)

Returns $stouch attribute $get, or C<undef> if $get is unavailable. The
following are valid C<$get>s:

=over 4

=item Template

Name of the template to be used, as specified by the C<-T> option. Set to
C<undef> if the C<-T> option was not used.

=item TemplateDir

Path to directory where templates are being stored.

=item TemplateParam

Hash ref of substitution targets and the text that is to replace them.

=item Files

Array ref of files to be created.

=item Quiet

Boolean determining whether informative message output is to be silenced or not.

=back

=back

=head1 AUTHOR

Written by Samuel Young, L<samyoung12788@gmail.com>.

=head1 COPYRIGHT

Copyright 2024, Samuel Young

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<stouch>

=cut
