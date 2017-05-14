package Benchmark::Harness::Profile;
use strict;

### ################################################################################################
sub new {
    my ($cls, $filename, $asSchema) = @_;

    my $self = {
         'source'	=> $filename
        ,'schema'	=> $asSchema
    };

#    ($self->{schema}) = ($xmlClass->[2]->[0]->getAttribute('xsi:noNamespaceSchemaLocation') =~ m{BenchmarkHarness([\w\d]+)\.xsd} ) unless ( $asSchema );
    eval "use Benchmark::Harness::Profile::$asSchema";
    die $@ if $@;
    my $graph = eval "new Benchmark::Harness::Profile::$asSchema(\$self)";
	die $@ if $@;
	return $graph->generate();
}

### ################################################################################################
sub generate {
    my ($self) = @_;

	$self->{outFilename} = $self->{source};
	$self->{outFilename} =~ s{\.[\w\d]*$}{.Profile.htm};

    open PRF, ">$self->{outFilename}";
    print PRF <<EOT;
<html><head></head><body>
<table width=100% align=center>
<tr><td align=left width=50%><h2>Profile Report</h2>from $self->{source}</td><td width=25% align=right valign=bottom>Total<br>Events</td><td width=25% align=right valign=bottom>Total<br>Time</td></tr>
<tr><td colspan=3><hr></td></tr>
EOT
	for ( sort Sort @{$self->{subroutines}} ) {
		next unless defined $_->{totalevents};
		my $entryminusexit = $_->{entryminusexit}?"<font color=red> (entered $_->{entryminusexit} more times than exited)</font>":'';
		print PRF "<tr><td align=left>$_->{package}\:\:$_->{name}$entryminusexit</td><td align=right>$_->{totalevents}</td><td align=right>$_->{totaltime}</td></tr>";
	}
    print PRF "</table></body></html>";
    close PRF;

	return $self;
}


sub Sort {
	return defined $a->{latesttime} unless defined $b->{latesttime};
	return -1 unless defined $a->{latesttime};
	return $a->{latesttime} <=> $b->{latesttime};
}

### ################################################################################################
### ################################################################################################
### ################################################################################################
package Benchmark::Harness::SAX::Profile;
use Benchmark::Harness::SAX;
use base qw(Benchmark::Harness::SAX);
use strict;

## #################################################################################
sub new {
    my $self = bless shift->SUPER::new(	# Checks validity of global static
		{								# context and adds these attributes
             'totaltime'   => 0
            ,'totalevents' => 0
        }
	);

    map {
        push @{$self->{capture}}, $_;	# Record the attributes we want to capture,
        push @{$self->{data}}, [];		# and instantiate an array for each one.
    } @_;

    return $self;
}

sub start_element {
    my ($self, $saxElm) = @_;

    if ( my $tagName = $self->SUPER::start_element($saxElm) ) { # Capture the standard elements (e.g., <ID>);
		if ( ($$tagName eq 'T') ) {	 # was not captured by SUPER, so maybe it's ours?
			$self->{totalevents} += 1;
			my $attrs = $saxElm->{Attributes};
			my $subr  = $attrs->{'{}_i'}->{Value};
			my $data  = $self->{subroutines}->[$subr];
			$data->{totalevents} += 1;
			my $t = $attrs->{'{}t'}->{Value};
			$data->{firsttime} = $t unless $data->{firsttime};
			if ( $attrs->{'{}_m'}->{Value} eq 'E' ) {
				$data->{lastentrytime} = $t;
				$data->{entryminusexit} += 1;
			} else {
				$data->{lastexittime} = $t;
				$data->{totaltime} = $t - $data->{lastentrytime};
				$data->{entryminusexit} -= 1;
			}
		}
	}
}

1;