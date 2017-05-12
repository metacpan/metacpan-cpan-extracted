#!perl
# File: jmerge.pl
# Desc: A program that examines a local JIRA backup file and then interogates
#       remote JIRA instances for data to be combined into a new backup file
#       in preparation of a project restore in order to import and integrate
#       the data from the remote system into a controlled instance.
#

# TODO Add in Perl documentations for the comman-line tool.
# TODO Flow down some of the options into the JWand object such as:
# TODO --verbose into JWand
# TODO --debug into JWand

use strict;
use warnings;
use Data::Dumper; my $dd;

use Getopt::Long; ## qw(:config no_ignore_case bundling no_auto_abbrev);
use Pod::Usage;

#
# <instance-definition> 
#	:= <usr> , ':' , <pwd> , ':' , <uri-spec> , ':' <project-list> ;
# <uri-spec>
#	:= <protocol> , '://' , <host-spec> , <path-spec> ;
# <protocol>
#	:= [ 'http' | 'https' | 'file' ] ;
# <host-spec>
#	:= <host> , [ ':' <port> ] ;
# <path-spec>
#	:= [ '' | <path-segment> ] ;
# <path-segment>
#	:= '/' , { <alpha> | <digit> | <printable> } , [ <path-segment> ] ;
# <project-list>
#	:= { <alpha> } , [ ',' { <alpha> } ] ;

sub _parse_instance_option {
	my ($ahref,$str) = @_;
	my ($usr,$pwd,$uri,$prj);
	return(undef);
}

sub _quick_line_preparation {
	my $val = shift;
	$val =~ s/\n\r//g;		# trailing \n\r  e.g. chomp() or chop()
	$val =~ s/\#.*//g;		# everything after a hash ('#') character  e.g. comment
	$val =~ s/\s+$//g;		# any trailing whitespace
	$val =~ s/^\s+//g;		# any leading whitespace
	# print("'$val'\n");
	return($val);	
}

sub _parse_configuration_file {
	my ($file) = @_;
	my ($fh,$val,$a,$b,$c,$d);
	my @opts = ( );
	
	return (undef) if ((! -f $file) || (!open($fh,"<$file")));

	while (<$fh>) {
		my $val = _quick_line_preparation($_);
		if ($val =~ m/^(\S+)\s+(\S+)\s+\{/) {
			$a = lc($1);
			$b = $2;
			my $blk = ( );
			$blk->{block} = $a;
			$blk->{bname} = $b;
			$blk->{setting} = { map => undef };
			push(@opts,$blk);
			while (<$fh>) {
				$val = _quick_line_preparation($_);
				last if ($val =~ m/^}$/);
				if (    ($val =~ m/^(\S+)\s+"(\S+)"$/)
					 || ($val =~ m/^(\S+)\s+(\S+)$/) ) {
					$a = lc($1);
					$b = $2;
					$blk->{setting}->{$a} = $b;
					$blk->{setting}->{type} = 'file' if ($a eq 'fileset');
					$blk->{setting}->{type} = 'http' if ($a eq 'url');					
					next;
				} elsif (  ( $val =~ m/^(map\-\S+)\s+(m\/.*\/)\s+=>\s+"(.*)"$/i )
						|| ( $val =~ m/^(map\-\S+)\s+(m\/.*\/)\s+=>\s+(s\/.*\/g?)$/i )
						|| ( $val =~ m/^(map\-\S+)\s+(m\/.*\/)\s+=>\s+(\S+)$/i )
						|| ( $val =~ m/^(map\-\S+)\s+"(.*)"\s+=>\s+"(.*)"$/i )
						|| ( $val =~ m/^(map\-\S+)\s+"(.*)"\s+=>\s+(s\/.*\/g?)$/i )
						|| ( $val =~ m/^(map\-\S+)\s+"(.*)"\s+=>\s+(\S+)$/i )
						|| ( $val =~ m/^(map\-\S+)\s+(\S+)\s+=>\s+"(.*)"$/i )
						|| ( $val =~ m/^(map\-\S+)\s+(\S+)\s+=>\s+(s\/.*\/g?)$/i )
						|| ( $val =~ m/^(map\-\S+)\s+(\S+)\s+=>\s+(\S+)$/i )
						) {
					$a = lc($1);
					$b = $2;
					$c = $3;
					$d = $4;
					push(@{$blk->{setting}->{$a}},{$b,$c});
					next;
				}		
			}  # end while()
		}	
	}  # end while()
	close($fh);
	
	return(\@opts);
}

my $OPTS = ( );
my $PARSER = Getopt::Long::Parser->new( config => [ 'no_ignore_case', 'bundling', 'no_auto_abbrev' ]);
$PARSER->getoptions(
    '' => \$OPTS->{STDIO}
	,'alittleoldhelp|?' => \$OPTS->{HELP}
    ,'help' => \$OPTS->{MANUAL}
    ,'verbose|v!' => \$OPTS->{VERBOSE}
    ,'quiet!' => sub { $OPTS->{VERBOSE} = 0; }
    ,'debug+' => \$OPTS->{DEBUG}
    ,'config|cfg=s' => sub {
    	my ($option,$string) = @_;
		$OPTS->{CONFIG} = _parse_configuration_file($string);
        }
    ,'grab-resolutions' => \$OPTS->{GRAB_RESOLUTIONS}
    ,'grab-priorities' => \$OPTS->{GRAB_PRIORITIES}

#    ,'alittlehelp|?' => \$OPTS->{HELP}
#    ,'password|P=s' => \$OPTS->{PASSWORD}
#    ,'username|user|U=s' => \$OPTS->{USERNAME}
#    ,'url|u=s' => sub { my ($option,$url) = @_; $OPTS->{SOAP_URL} = $OPTS->{SITE_URL} = $url; }
#    ,'site-url=s' => \$OPTS->{SITE_URL}
#    ,'soap-url=s' => \$OPTS->{SOAP_URL}
#    ,'project|projects|p=s' => sub { 
#    	   my ($option,$str) = @_;
#           $OPTS->{PROJECTS} = [ ] if (! $OPTS->{PROJECTS});
#    	   my @tmp = split(/,/,join(',',@{$OPTS->{PROJECTS}},$str));
#    	   $OPTS->{PROJECTS} =  \@tmp;
#        }
#    ,'define=s%' => sub {
#           my ($option,$key,$val) = @_;
#           $OPTS->{DEFINE} = ( ) if (! $OPTS->{DEFINE});
#      	   $OPTS->{DEFINE}->{$key} = $val;
#        }
#    ,'max-filesize=i' => \$OPTS->{MAX_FILESIZE}
#    ,'max-results|max-result|max_resultcount=i' => \$OPTS->{MAX_RESULTS}
#    ,'max-issues|issues=i' => \$OPTS->{MAX_ISSUES}
#    ,'max-attachments=i' => \$OPTS->{MAX_ATTACHMENTS}
#    ,'attachments' => sub { $OPTS->{MAX_ATTACHMENTS} = 0; }
#    ,'timeout|t=i' => \$OPTS->{TIMEOUT}
#    ,'infile|in|i=s' => \$OPTS->{INFILE}
#    ,'outfile|out|o=s' => \$OPTS->{OUTFILE}
#    ,'validate|V' => \$OPTS->{VALIDATE}
#    ,'loglevel|l=i' => \$OPTS->{LOGLEVEL}
#    ,'logfile=s' => \$OPTS->{LOGFILE}
#    ,'log+' => \$OPTS->{LOGLEVEL}
    ,'grab-components' => \$OPTS->{GRAB_COMPONENTS}
    ,'grab-statuses' => \$OPTS->{GRAB_STATUSES}
    ,'grab-projectroles' => \$OPTS->{GRAB_PROJECTROLES}
    ,'grab-versions' => \$OPTS->{GRAB_VERSIONS}
    ,'grab-globaldefs' => sub {
    		$OPTS->{GRAB_PRIORITIES} =
    		$OPTS->{GRAB_RESOLUTIONS} =
    		$OPTS->{GRAB_STATUSES} =
    		$OPTS->{GRAB_PROJECTROLES} = 1;
    	}
	,'grab-projectdefs' => sub {
			$OPTS->{GRAB_VERSIONS} =
			$OPTS->{GRAB_COMPONENTS} = 1;
		}
	,'uri=s' => sub {
			return(_parse_uri(@_));
		}
		
    ) or pod2usage(2);
if (defined($OPTS->{DEBUG}) && ($OPTS->{DEBUG} >= 2)) {
     $dd = Data::Dumper->new([$PARSER]); 
     print '[$PARSER]'," := (\n",$dd->Dump(),")\n"; 
}
if ($OPTS->{DEBUG} >= 2) { $dd = Data::Dumper->new([$OPTS]); print '[$OPTS]'," := (\n",$dd->Dump(),")\n"; }
if ($OPTS->{DEBUG} >= 2) { $dd = Data::Dumper->new([@ARGV]); print '[@ARGV]'," := (\n",$dd->Dump(),")\n"; }
pod2usage(1) if ($OPTS->{HELP});
pod2usage('-exitstatus' => 0, '-verbose' => 2) if ($OPTS->{MANUAL});

###
### START OF THE GUTS  
###

#
# Create and chain the JWands
#

use Comskil::JWand qw(:ALL);

my $wand;

foreach my $blk (@{$OPTS->{CONFIG}}) {
    if ($OPTS->{DEBUG} >= 2) { $dd = Data::Dumper->new([$blk]); print $dd->Dump(); }	
	next if (($blk->{block} ne 'source') || ($blk->{setting}->{type} ne 'http'));

	if ($OPTS->{DEBUG} >= 2) { $dd = Data::Dumper->new([$blk]); print $dd->Dump(); }

    my $tmp = Comskil::JWand->new( $blk->{setting}, 
    						{ 	timeout => 600
    							,debug => $OPTS->{DEBUG}
    							,verbose => $OPTS->{VERBOSE}
    							,bname => $blk->{bname}
    						} );
    						
	$wand = ( $wand ? $wand->appendToChain($tmp) : $tmp );    						
    if ($OPTS->{DEBUG} >= 3) { $dd = Data::Dumper->new([$wand]); print $dd->Dump(); }
}

my $lref = ( ); 
$lref->{priorities} = $wand->grabPriorities() if ($OPTS->{GRAB_PRIORITIES});
if ($OPTS->{DEBUG} == 2) { $dd = Data::Dumper->new([$lref->{priorities}]); print $dd->Dump(); 
	} elsif ($OPTS->{DEBUG} >= 3) { $dd = Data::Dumper->new([$lref]); print $dd->Dump();
}
if ($OPTS->{VERBOSE}) {
	print("priorities:");
	foreach my $key (@{$lref->{priorities}}) {
		print(" '",$key->{name},"'");
	}
	print("\n");
}

$lref->{resolutions} = $wand->grabResolutions() if ($OPTS->{GRAB_RESOLUTIONS});
if ($OPTS->{DEBUG} == 2) { $dd = Data::Dumper->new([$lref->{resolutions}]); print $dd->Dump(); 
	} elsif ($OPTS->{DEBUG} >= 3) { $dd = Data::Dumper->new([$lref]); print $dd->Dump();
}
if ($OPTS->{VERBOSE}) {
	print("resolutions:");
	foreach my $key (@{$lref->{resolutions}}) {
		print(" '",$key->{name}."'");
	}
	print("\n");
}

$lref->{statuses} = $wand->grabStatuses() if ($OPTS->{GRAB_STATUSES});
if ($OPTS->{DEBUG} == 2) { $dd = Data::Dumper->new([$lref->{statuses}]); print $dd->Dump(); 
	} elsif ($OPTS->{DEBUG} >= 3) { $dd = Data::Dumper->new([$lref]); print $dd->Dump();
}
if ($OPTS->{VERBOSE}) {
	print("statuses:");
	foreach my $key (@{$lref->{statuses}}) {
		print(" '",$key->{name},"'");
	}
	print("\n");
}
$lref->{project_roles}= $wand->grabProjectRoles() if ($OPTS->{GRAB_PROJECTROLES});
if ($OPTS->{DEBUG} == 2) { $dd = Data::Dumper->new([$lref->{project_roles}]); print $dd->Dump(); 
	} elsif ($OPTS->{DEBUG} >= 3) { $dd = Data::Dumper->new([$lref]); print $dd->Dump();
}
if ($OPTS->{VERBOSE}) {
	print("project_roles:");
	foreach my $key (@{$lref->{project_roles}}) {
		print(" '",$key->{name},"'");
	}
	print("\n");
}




exit(0);


$lref->{resolutions} = $wand->grabResolutions() if ($OPTS->{GRAB_RESOLUTIONS});
$lref->{statuses} = $wand->grabStatuses() if ($OPTS->{GRAB_STATUSES});
$lref->{project_roles}= $wand->grabProjectRoles() if ($OPTS->{GRAB_PROJECTROLES});
$lref->{components} = $wand->grabComponents(@{$OPTS->{PROJECTS}}) if ($OPTS->{GRAB_COMPONENTS});
$lref->{versions} = $wand->grabVersions(@{$OPTS->{PROJECTS}}) if ($OPTS->{GRAB_VERSIONS});
$lref->{project_info} = $wand->grabProjectInfo(@{$OPTS->{PROJECTS}});
$lref->{project_role_actors} = 
	$wand->grabProjectRoleActors($OPTS->{PROJECTS},$lref->{project_roles});

## $wand->grabAttachments('./attachments', @{$OPTS->{PROJECTS}}); 



## $dd = Data::Dumper->new([$wand]); print $dd->Dump();

__END__   ### End of Program Source
=head1 NAME

jira-remote-merge.pl - A tool to integrate a remote JIRA instance with a local XML backup file.

=head1 SYNOPSIS
 
jira-remote-merge.pl [<option> [...]] [<arg> [...]]

=head1 OPTIONS

=over 15

=item -?,--help

print short and long help messages 

=item --verbose

show run-time progress information

=item -U,--url

URL for accessing SOAP functions of the JIRA instance

=item -U,--username

=item -P,--password

username and password used to authenticate to the remote server
 
=item -i,--infile

=item -o,--outfile

=item -V,--validate

=back
 
=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

There can be several paragraphs.

Each with a line in between.

=head2 Additional Options

=over 15

=item --debug

Display debug information about program structures and status as it is running.
This is useful to make sure the program is parsing and acting on the data in ways you
expect.

=item --loglevel

=item --logfile

=item -t,--timeout

=item -p,--project

=item -d,--define

=item --soap-url

=item --site-url

=item -q,--quiet

=item --max_filesize

=item --max_requests

=item --max_attachments

=item --max_issues

=back

=cut
### EOF