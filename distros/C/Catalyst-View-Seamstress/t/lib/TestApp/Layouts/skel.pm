package TestApp::Layouts::skel;

# cmdline: /usr/local/bin/spkg.pl skel.html

use strict;
use warnings;

use base qw(Class::Prototyped HTML::Seamstress);


;
use base qw( TestApp::View::Test );
use vars qw($html);

our $tree;

#warn HTML::Seamstress::Base->comp_root(); 
#HTML::Seamstress::Base


#$html = __PACKAGE__->html(__FILE__ => 'html') ;
$html = __FILE__;

sub new {
#  my $file = __PACKAGE__->comp_root() . 'lyst-View-Seamstress-2.0/t/lib/TestApp/Layouts/skel.html' ;
  my $file = __PACKAGE__->html($html => 'html');

  -e $file or die "$file does not exist. Therefore cannot load";

  $tree =HTML::TreeBuilder->new;
  $tree->store_declarations;
  $tree->parse_file($file);
  $tree->eof;
  
  bless $tree, __PACKAGE__;
}

sub process {
  my ($tree, $c, $stash) = @_;

  # $tree->look_down(id => $_)->replace_content($stash->{$_})
  #     for qw(name date);

  $tree;
}

sub fixup {
  my ($tree, $c, $stash) = @_;

  $tree;
}




1;
