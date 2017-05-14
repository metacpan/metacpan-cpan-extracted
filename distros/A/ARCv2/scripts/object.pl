#!/usr/local/bin/perl -w

use strict;

exit 0 unless @ARGV;

my @files = `find $ARGV[0] | grep '.pm\$'`;

my $base = $ARGV[1];
$base =~ s/\//::/g;
$base =~ s/\.pm//g;

my %iter;
my %methods;
my %members;

foreach (@files) {
	open (FH,"<$_");
	my $name;
	my $doc = { in => "", out => "", desc => ""};
	while (<FH>) {
		if (/package\s+(.*?);/) {
			$name = $1;
			$methods{$name} = {};
			$members{$name} = {};
		} elsif (/ISA.+qw\((.*?)\)/) {
			$iter{$name} = $1;
		} elsif (/^sub\s+(\w+)/) {
			if ($1 =~ m/members/) {
				while (<FH>) {
					my $m = $_;
					if ($m =~ /\s+(\w+)\s+=>\s+(.*?),/) {
						my $n = $1;
						$members{$name}->{access_level($n)}->{$n}->{value} = $2;
						if ($m =~ /#(\s*)(.*)$/) {
							$members{$name}->{access_level($n)}->{$n}->{desc} = $2;
						}
					}
					last if (/\};/);
			    }
			} else {
				$methods{$name}->{access_level($1)}->{$1}->{doc} = $doc;
			}
			$doc = { desc => ""};
		} elsif (/^##(\s*)(.*)$/) {
			my $t = $2;
			if ($t =~ /^in>\s+(.*)/) {
				$doc->{in} .= $1;
			} elsif ($t =~ /^out>\s+(.*)/) {
				$doc->{out} .= $1."\n";
			} elsif ($t =~ /^eg>\s+(.*)/) {
				$doc->{eg} .= $1."\n";
			} else {
				$doc->{desc} .= $t."\n";
			}
		}
	}
	close(FH);
}

die "Given class not found, cannot build object structure. ($base)" if (!$members{$base} && !$methods{$base});

podout("head1","Class VARIABLES");
my %ready;
showclass_members($base,0,0,"public");
showclass_members($base,0,0,"protected");
showclass_members($base,0,0,"private");

%ready = ();
podout("head1","Class METHODS");
showclass_methods($base,0,0,"public");
showclass_methods($base,0,0,"protected");
showclass_methods($base,0,0,"private");

print "\n";

sub access_level
{
	$_ = $_[0];
	if (/^__/) {
		return "private";
	} elsif (/^_/) {
		return "protected";
	} else {
		return "public";
	}
}

sub issuperior
{
	my ($type,$cname,$item,$acl) = @_;

	my $text = "";
	while ($cname = $iter{$cname}) {
		if (eval '$'.$type.'{$cname}->{$acl}->{$item}') {
			$ready{$item} = 1;
			$text = "reimplemented from $cname";
			last;
		}
	}
	return $text;
}

sub showmembers 
{
	my $inh = shift;
	my $cname = shift;
	my $aclevel = shift;
	my %ac = @_;
	%ac = %{$ac{$aclevel}};
	
	foreach (sort { uc($a) cmp uc($b) } keys %ac) {
# superior classes maybe have this method, we want to know which one
		next if $ready{$_};
		my $inherited = issuperior("members",$cname,$_,$aclevel); 
		$inherited |= $inh;
		if ($inherited ne "") {
			$inherited = "I<".$inherited.">"; 
		} else {
			$inherited = "";
		}
		
		podout("item",$_," ",$inherited);

		if ($ac{$_}->{desc}) {
			textout("B<Description>: ",$ac{$_}->{desc});
		}
		if ($ac{$_}->{value}) {
			textout("B<Default value>: ",$ac{$_}->{value});
		}
	}
}

sub showmethods
{
	my $inh = shift;
	my $cname = shift;
	my $aclevel = shift;
	my %ac = @_;
	%ac = %{$ac{$aclevel}};
	foreach (sort { uc($a) cmp uc($b) } keys %ac) {
# superior classes maybe have this method, we want to know which one
		next if $ready{$_};
		my $inherited = issuperior("methods",$cname,$_,$aclevel); 
		$inherited |= $inh;
		if ($inherited ne "") {
			$inherited = "I<".$inherited.">"; 
		} else {
			$inherited = "";
		}
		podout("item","$_ ( ",$ac{$_}->{doc}->{in} ? $ac{$_}->{doc}->{in} : "" ," ) ",$inherited);
		
		if ($ac{$_}->{doc}->{desc}) {
			textout("B<Description>: ",$ac{$_}->{doc}->{desc});
		}

		if ($ac{$_}->{doc}->{out}) {
			textout("B<Returns:> ",$ac{$_}->{doc}->{out});
		}

		if ($ac{$_}->{doc}->{eg}) {
			textout("B<Example:>");
			textout($ac{$_}->{doc}->{eg});
		}
	}
}

sub showclass_methods
{
	my ($name,$inl,$inh,$acc) = @_;

	podout("head3",uc("$acc methods")) unless $inh;
	if ($methods{$name}->{$acc}) {
		podout("over",2);
		showmethods($inh ? "inherited from ".$name : "" ,$name,$acc,%{$methods{$name}});	
		podout("back");
	}

	if ($acc ne "private" && $iter{$name} ) {
		foreach (split(/\s+/,$iter{$name})) {
			showclass_methods($_,$inl+1,1,$acc);
		}
	}
}

sub showclass_members
{
	my ($name,$inl,$inh,$acc) = @_;

	podout("head3",uc("$acc members")) unless $inh;
	if ($members{$name}->{$acc}) {
	
		podout("over",2);
		showmembers($inh ? "inherited from ".$name : "",$name,$acc,%{$members{$name}});	
		podout("back");
	}

	if ($acc ne "private" && $iter{$name} ) {
		foreach (split(/\s+/,$iter{$name})) {
			showclass_members($_,$inl+1,1,$acc);
		}
	}
}

sub podout 
{
	my $h = shift;
	
	print "\n=",$h," ",@_ ? join("",@_):"","\n";
}

sub textout 
{
	print "\n",@_,"\n";
}

sub verbout 
{
#	if ($args{v})
#	print STDERR join(" ",@_),"\n";
}
