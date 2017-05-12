#!/usr/bin/perl
#

use Scriptalicious;
    -progname => 'ct2pod';

=head1 NAME

ct2pod - convert Class::Tangram source files to POD

=head1 SYNOPSIS

ct2pod [options] module.pm

=head1 DESCRIPTION

C<ct2pod> produces POD documentation files from Class::Tangram style
Perl Modules.  This script can either run on a single Perl module
(traditional L<Class::Tangram> style), or generate a series of POD
files from a Tangram::Schema compatible data structure
(L<Class::Tangram::Generator> style).

POD files are written in the same directory as the Perl module file.
POD files are not updated unless they are older than the module files.

=head1 COMMAND LINE OPTIONS

=over

=item B<-s, --schema>

Specify to look for a schema that contains a data structure describing
several classes at once.  For this to work, the module must call
C<Class::Tangram::Generator::new> with the schema structure you want
to generate POD files for.

=item B<-t, --template=FILE>

Specify the name of the Template Toolkit template to use as a source
for making the POD files.  The default is a built-in template.

=item B<-h, --help>

Display a program usage screen and exit.

=item B<-V, --version>

Display program version and exit.

=item B<-v, --verbose>

Verbose command execution, displaying things like the
commands run, their output, etc.

=item B<-q, --quiet>

Suppress all normal program output; only display errors and
warnings.

=item B<-d, --debug>

Display output to help someone debug this script, not the
process going on.

=back

=cut

use strict;
use warnings;
use Pod::Parser;
use Data::Dumper;
use Template;

our $VERSION = '1.00';

#---------------------------------------------------------------------
#  generate_pod($filename)
#---------------------------------------------------------------------
{
    no strict 'refs';
    use Set::Object;
    sub generate_pod($) {
	my $filename = shift;

	require $filename;

	$filename =~ s{\.\w+$}{};

	my @stash_stack = \%::;   #uh-oh!
	my $seen_stashes = Set::Object->new(\%::);
	$Data::Dumper::Indent = 1;
	$Data::Dumper::Purity = 1;

	my @schemas;

	while ( my $stash = shift @stash_stack ) {
	    while ( my ($symbol, $entry) = each %$stash ) {
		#say "in $stash: $symbol => $entry";
		if ( $symbol =~ m{::$} ) { #and ref $entry eq "GLOB" ) {
		    #say "TRAVERSING STASH: $stash ($entry), ".ref($entry);
		    my $new_stash = \%{*$entry};
		    push @stash_stack, $new_stash
			if $seen_stashes->insert($new_stash);
		}
		elsif ( $symbol =~ m{^(schema|fields)$} ) {
		    (my $class = $entry) =~ s{\$\*}{};
		    $class =~ s{::.*?$}{};
		    ($Data::Dumper::Varname = "$entry") =~ s{\*}{};
		    print Data::Dumper->Dump([ ${*{$entry}{SCALAR}} ], [$class]);
		}
	    }
	}
    }
}

sub read_pod(\*) {
    my $fh = shift;

    my @output;
    while ( defined <$fh> ) {
	push @output, $_;
    }
    close $fh;

    if ( $? ) {
	barf "sub-process ".($?&255 ? "killed by signal $?"
			     : "exited with error code ".($?>>8));
    }
    return join "", @output;
}

#=====================================================================
#  MAIN SECTION STARTS HERE
#=====================================================================
my $is_schema;

getopt ( "schema|s" => \$is_schema,
       );


while ( my $filename = shift ) {
    generate_pod($filename);
next;
    die "fork failed; $!" unless defined (my $pid = open POD, "-|");

    generate_pod $filename unless $pid;
    my $pod = read_pod(*POD) if $pid;
}

__DATA__

=head1 NAME

[% IF pod.name %][% pod.name %][% ELSE %]
[% class %] - Class::Tangram data class
[% END %]

=head1 SYNOPSIS

[% IF pod.synopsis %][% pod.synopsis %][% ELSE %]
  use [% class %];

  my $object = [% class %]->new
[% IF required %]
      (
[% FOR item = required %]
        [% item.name %] => [% item.example %],
[% END %]
      );
[% END %][%# required %]
[% END %]

[% FOR type = fields.keys.sort %]
[% IF type.match("i?set") %]
[% FOR fields = fields.$type.keys.sort %]
  $obj->
[% END %]
[% END %]

=head1 DESCRIPTION

[% IF pod.description %][% pod.description %][% ELSE %]
[% 
