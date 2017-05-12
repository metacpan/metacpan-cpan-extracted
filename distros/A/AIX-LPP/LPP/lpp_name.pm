package AIX::LPP::lpp_name;

require 5.005_62;
use strict;
use warnings;

our $VERSION = '0.5';

sub new {
    my $class = shift;
    my %param = @_;
    my $self = {};

    if (defined $param{FORMAT}) { $self->{FORMAT} = $param{FORMAT}}
        else { $self->{FORMAT} = '4'}
    if (defined $param{PLATFORM}) { $self->{PLATFORM} = $param{PLATFORM}}
        else { $self->{PLATFORM} = 'R'}
    if (defined $param{TYPE}) { $self->{TYPE} = $param{TYPE}}
        else { $self->{TYPE} = 'I'}
    if (defined $param{NAME}) { $self->{NAME} = $param{NAME}}
        else { $self->{NAME} = 'test.lpp'}
    $self->{FILESET} = {};
    bless $self, $class;
    return $self;
}

sub lpp {
    my $self = shift;
    return ( $self->{NAME},$self->{TYPE},$self->{FORMAT},$self->{PLATFORM},
	keys %{$self->{FILESET}} ) unless @_;
    my %param = @_;
    if (defined $param{FORMAT}) { $self->{FORMAT} = $param{FORMAT}}
    if (defined $param{PLATFORM}) { $self->{PLATFORM} = $param{PLATFORM}}
    if (defined $param{TYPE}) { $self->{TYPE} = $param{TYPE}}
    if (defined $param{NAME}) { $self->{NAME} = $param{NAME}}
    return ( $self->{NAME},$self->{TYPE},$self->{FORMAT},$self->{PLATFORM},
	keys %{$self->{FILESET}} );
}

sub fileset {
    my $self = shift;
    my $fsname = shift;
    my %param = @_;
    if ( $#_ == -1 ) {
        return ($self->{FILESET}{$fsname}{NAME},$self->{FILESET}{$fsname}{VRMF},
	$self->{FILESET}{$fsname}{DISK},$self->{FILESET}{$fsname}{BOSBOOT},
	$self->{FILESET}{$fsname}{CONTENT},$self->{FILESET}{$fsname}{LANG},
	$self->{FILESET}{$fsname}{DESCRIPTION},
	$self->{FILESET}{$fsname}{COMMENTS});
    } else {
	if ( ! exists $self->{FILESET}{$fsname} ) {
            $self->{FILESET}{$fsname} = {
    	    	NAME => $fsname,
		VRMF => $param{VRMF},
		DISK => $param{DISK},
		BOSBOOT => $param{BOSBOOT},
		CONTENT => $param{CONTENT},
		LANG => $param{LANG},
		DESCRIPTION => $param{DESCRIPTION},
		COMMENTS => $param{COMMENTS},
		REQ => [ ],
		SIZEINFO => { }
            };
        } else {


	}
    }
    return ( $self->{FILESET}{$fsname}{NAME},
	$self->{FILESET}{$fsname}{VRMF},
	$self->{FILESET}{$fsname}{DISK},
	$self->{FILESET}{$fsname}{BOSBOOT},
	$self->{FILESET}{$fsname}{CONTENT},
	$self->{FILESET}{$fsname}{LANG},
	$self->{FILESET}{$fsname}{DESCRIPTION},
	$self->{FILESET}{$fsname}{COMMENTS});
}

sub sizeinfo {
    my $self = shift;
    my $fset = shift;
    my $size_ref = shift;

    $self->{FILESET}{$fset}{SIZEINFO} = $size_ref;
    return $self->{FILESET}{$fset}{SIZEINFO};
}

sub requisites {
    my $self = shift;
    my $fset = shift;
    my $ref_req = shift;

    $self->{FILESET}{$fset}{REQ} = $ref_req;
    return $self->{FILESET}{$fset}{REQ};
}

sub validate {

}

sub read {
    my $class = shift;
    my $fh = shift;
    my $self = {};
    bless $self, $class;
    
    chomp (my $line = <$fh>);
    my ($format,$platform,$type,$name,$token) = split / /, $line;
    $self->lpp(NAME => $name, FORMAT => $format, TYPE => $type,
		PLATFORM => $platform);
    chomp ($line = <$fh>);

# add while loop here to process fileset headers

    my ($fsn,$vrmf,$disk,$bosboot,$content,$lang,@desc) = split / /, $line;
    $self->fileset($fsn, NAME => $fsn,VRMF => $vrmf,DISK => $disk,
	BOSBOOT => $bosboot, CONTENT => $content, LANG => $lang,
	DESCRIPTION => join ' ', @desc);

    chomp ($line = <$fh>) until $line =~ /^\[/;
    chomp ($line = <$fh>);

    FSDATA: { do {
	chomp $line;
	my @reqs;
        last if $line =~ /^\]/;

	REQS: { do {
	    push @reqs, [ split (/ /, $line) ];
	    chomp ($line = <$fh>);
	} until $line =~ /^%/; }

	$self->requisites($fsn,\@reqs);

	chomp ($line = <$fh>);
	SIZEINFO: { do {
	    my ($loc,@size) = split (/ /, $line);
	    $self->{FILESET}{$fsn}{SIZEINFO}{$loc} = join ' ', @size;
	    chomp ($line = <$fh>);
	} until $line =~ /^%/; }

	chomp ($line = <$fh>);
	THIRD: { do {
	} until $line =~ /^%/; }

	chomp ($line = <$fh>);
	FOURTH: { do {
	} until $line =~ /^%/; }

	chomp ($line = <$fh>);
	FIFTH: { do {
	} until $line =~ /^%/; }
	
    } while ($line = <$fh>); }

    return $self;
}

sub write {
    my $self = shift;
    my $fh = shift;

    print $fh join ' ', $self->{FORMAT}, $self->{PLATFORM}, $self->{TYPE},
	$self->{NAME}, "{\n";
    foreach my $fileset (keys %{$self->{FILESET}} ) {
        print $fh join ' ', $self->{FILESET}{$fileset}{NAME},
		$self->{FILESET}{$fileset}{VRMF},
		$self->{FILESET}{$fileset}{DISK},
		$self->{FILESET}{$fileset}{BOSBOOT},
		$self->{FILESET}{$fileset}{CONTENT},
		$self->{FILESET}{$fileset}{LANG},
		$self->{FILESET}{$fileset}{DESCRIPTION}, "\n[\n";

	for my $i ( 0 .. $#{$self->{FILESET}{$fileset}{REQ}} ) {
	    print $fh join ' ',@{${$self->{FILESET}{$fileset}{REQ}}[$i]},"\n";
        }

	print $fh "%\n";
	foreach my $key (sort keys %{$self->{FILESET}{$fileset}{SIZEINFO}}) {
	    print $fh join ' ', $key,
		$self->{FILESET}{$fileset}{SIZEINFO}{$key}, "\n";
        }

	print $fh "%\n%\n%\n%\n]\n";
    }

    print $fh "}";
}

1;
__END__
=head1 NAME

AIX::LPP::lpp_name - Perl module for manipulation of an AIX lpp_name file

=head1 SYNOPSIS

  use AIX::LPP::lpp_name;

  $x = lpp_name->new();
  $x->lpp(NAME => 'test.lpp',TYPE => 'I',PLATFORM => 'R',FORMAT => '4');
  $x->fileset('test.lpp.rte', VRMF => '1.0.0.0',DISK => '01',BOSBOOT => 'N',
	CONTENT => 'I', LANG => 'en_US', DESCRIPTION => 'test.lpp description',
	COMMENTS => '');
  my @reqs = [ ['*prereq','bos.rte','4.3.3.0'] ];
  $x->requisites('test.lpp.rte', \@reqs);
  my %sizes = { '/usr' => '5', '/etc' => '1' };
  $x->sizeinfo('test.lpp.rte', \%sizes);
  $x->write(\*out_fh);

  or

  $x = lpp_name->read(\*in_fh);
  my %lppdata = $x->lpp();
  my %fsdata = $x->fileset('test.lpp.rte');
  my $req_ref = $x->requisites('test.lpp.rte');
  my $size_ref = $x->sizeinfo('test.lpp.rte');
  
=head1 DESCRIPTION

AIX::LPP::lpp_name is a class module for reading, creating, and modifying
AIX lpp_name files.  The lpp_name file is an internal component of AIX
packages (called LPPs).  LPPs consist of filesets and information about
installing them.  This information can include: prerequisites, filesystem
requirements, copywrites, etc..

=head1 CONSTRUCTOR METHODS

=over 4

=item $x = lpp_name->new();

The simple form of the new constructor method creates an empty lpp_name
object.  This object is then modified using lpp() and fileset() object
methods.  Basic LPP information can also be passed to new() as follows: ...

=item $x = lpp_name->read(\*in_fh);

Alternatively, a new lpp_name object can be create by reading data from
an lpp_name formatted file. read() is both a class method and an instance
method (or it will be when I'm finished).

=head1 OBJECT METHODS

=over 4

=item lpp()

=item fileset()

=item requisites()

=item sizeinfo()

=item read()

=item write()

=item validate()

Not yet implemented.

=back

=head1 AUTHOR

Charles Ritter, critter@aixadm.org

=head1 SEE ALSO

The installp manpage, IBM LPP package format documentation.
