#!/usr/bin/perl

#demonstrates the usage of the HList widget.

use strict;
use CGI qw(:standard);
use CGI::Widget::HList;
use CGI::Widget::HList::Node;

my $ROOT = '/home/allenday/public_html/dbrowse';

my %o = map {$_=>1} param("o");
my %c = map {$_=>1} param("c");

#lets make the tree
my $root = CGI::Widget::HList::Node->new();
   $root->name("curio/");
   $root->link(\&alink);
   $root->close unless $o{$root->name};
descend($root,$ROOT);

print header();
print start_html;
my $hlist = CGI::Widget::HList->new(-root=>$root,
																		-render_node=>\&nlink,
																		);
print $hlist->html;
print end_html;

#recurse through directories
sub descend {
		my($parent,$base) = @_;
		my @content = get_content($base);

		foreach my $c (@content){
				my $daughter = CGI::Widget::HList::Node->new;
				$parent->add_daughter($daughter);
				$daughter->name("$base/$c");
				$daughter->link(\&alink);
				next if -f "$base/$c";

				$daughter->close unless $o{$c};
				$daughter->pregnant(1) unless $o{$c};

				descend($daughter,"$base/$c") if $o{$c};
		}
}

sub nlink {
		my $node = shift;
		my $name = $node->name;
		$name =~ s!.+/(.+)!$1!;
    my %to = %o;
    my %tc = %c;

    my $img = 
				$node->pregnant  ?     $hlist->img_close  :
				$node->state     ? 
						$node->daughters ? $hlist->img_open :
								$hlist->img_leaf   :
						$node->daughters ? $hlist->img_close  :
								$hlist->img_leaf   ;

		$to{$name} ? delete $to{$name} && $tc{$name}++ 
 		           : $to{$name}++ ;

    my $o = keys %to ? ";o=".join ";o=",keys %to : '' ;
		my $c = keys %tc ? ";c=".join ";c=",keys %tc : '' ;

		my $return = a({-name=>$name});
		$return   .= ($node->daughters || $node->pregnant)
				           ? a({-href=>script_name."?".$o.$c."#".$name},$img)
									 : $img;

		return $return;
}

sub alink {
		my $node = shift;
		my $name = $node->name;
		$name =~ s!.+/(.+)!$1!;

		return font({-size=>"-1"},
           "$name ".(sprintf "%8.2f",((stat $node->name)[7])/1048576)."MB") 
    if -f $node->name;

		return font({-size=>"-1"},$name);
}

sub get_content {
		my $path = shift;
		my @return = ();
    opendir(D,$path);
		foreach my $d (readdir(D)){
				next if $d =~ /^[\.]+$/;
				push @return, $d ;
		}
		closedir(D);
		return sort @return;
}












