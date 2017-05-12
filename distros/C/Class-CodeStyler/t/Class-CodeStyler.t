# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-CodeStyler.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 1;
#BEGIN { use_ok('Class::CodeStyler') };

use Test;
use Class::CodeStyler;
BEGIN { plan tests => 7 }

#########################

my $p2 = Class::CodeStyler::Program::Perl->new(print_bookmarks => 1);
$p2->code("sub function_operator");
$p2->open_block();
	$p2->code("my \$self = shift;");
	$p2->code("my \$arg1 = shift;");
	$p2->code("my \$arg2 = shift;");
	$p2->code("return \$arg1->eq(\$arg2);");
$p2->close_block();
$p2->prepare();

ok ($p2->print(), "sub function_operator\n{\n  my \$self = shift;\n  my \$arg1 = shift;\n  my \$arg2 = shift;\n  return \$arg1->eq(\$arg2);\n}\n", 
	'open/close_block()');
ok ($p2->raw(), "sub function_operator{my \$self = shift;my \$arg1 = shift;my \$arg2 = shift;return \$arg1->eq(\$arg2);}", 
	'raw()');

my $p = Class::CodeStyler::Program::Perl->new(print_bookmarks => 1, program_name => 'testing.pl', tab_size => 4);
ok ($p->program_name(), 'testing.pl', 'program_name()');

$p->open_block();
	$p->code("package MyBinFun;");
	$p->bookmark('subs');
	$p->indent_off();
	$p->comment("Subroutines above...");
	$p->indent_on();
$p->close_block();
$p->prepare();
ok ($p->print(), "{\n    package MyBinFun;\n    # BOOKMARK ---- subs\n#Subroutines above...\n}\n", 
	'tab_size, indent_on/off, comment()');

$p->jump('subs');
$p->add($p2);
$p->clear();
$p->prepare();
ok ($p->print(), qq~{\n    package MyBinFun;\n    sub function_operator\n    {\n        my \$self = shift;\n        my \$arg1 = shift;\n        my \$arg2 = shift;\n        return \$arg1->eq(\$arg2);\n    }\n    # BOOKMARK ---- subs\n#Subroutines above...\n}\n~, 'jump(), clear(), add()');

$p->return();
$p->divider();
$p->comment('Next package follows...');
$p->open_block();
	$p->code("package MyUFun;");
$p->close_block();
$p->clear();
$p->prepare();

ok ($p->print(), qq~{\n    package MyBinFun;\n    sub function_operator\n    {\n        my \$self = shift;\n        my \$arg1 = shift;\n        my \$arg2 = shift;\n        return \$arg1->eq(\$arg2);\n    }\n    # BOOKMARK ---- subs\n#Subroutines above...\n}\n#----------------------------------------------------------------------\n#Next package follows...\n{\n    package MyUFun;\n}\n~, 'return(), divider()');


# anchor:

my $p3 = Class::CodeStyler::Program::Perl->new(print_bookmarks => 1);
$p3->code("sub function_operator");
$p3->open_block();
  $p3->code("my \$self = shift;");
  $p3->code("my \$arg1 = shift;");
  $p3->code("my \$arg2 = shift;");
  $p3->newline_off();
  $p3->code("while (defined <STDIN> && \$_ = ");
  $p3->anchor_set();
  $p3->newline_on();
  $p3->code("sub mysplit");
  $p3->open_block();
    $p3->code("return split(\"[|]\");");
  $p3->close_block();
  $p3->anchor_return();
  $p3->newline_on();
  $p3->code("&mysplit())");
  $p3->code("return \$arg1->eq(\$arg2);");
$p3->close_block();
$p3->prepare();
ok ($p3->print(), qq~sub function_operator\n{\n  my \$self = shift;\n  my \$arg1 = shift;\n  my \$arg2 = shift;\n  while (defined <STDIN> && \$_ = &mysplit())\n  return \$arg1->eq(\$arg2);\n}\nsub mysplit\n{\n  return split(\"[|]\");\n}\n# ANCHOR ---- 7\n~, 'anchor');

#my $prog = Class::CodeStyler::Program->new(print_bookmarks => 1, program_name => 'myprogram', tab_size => 4);
#$prog->packages()->bookmark('My::Package');
#ok ($prog->packages()->jump('My::Package')->p_element()->data(), 'My::Package', 'packages->jump()');
#ok ($prog->packages()->jump('My::PackageX'), '0', 'packages->jump()');
#$prog->packages()->jump('My::Package');
#$prog->packages()->open_block();
#	$prog->packages()->code("package My::Package;");
#	$prog->packages()->indent_off();
#	$prog->packages()->comment("Subroutines above...");
#	$prog->packages()->indent_on();
		#
#$prog->inline()->functions()->code("use Inline C => <<'END_INLINE'");
#$prog->inline()->functions()->bookmark('apache_split');
#$prog->inline()->functions()->code("AV* apache_split (SV* sv_inp, int numflds)");
#$prog->inline()->functions()->open_block();
#$prog->inline()->functions()->code("register char *p;");
#$prog->inline()->functions()->close_block();
#&csv_split($prog);
#$prog->inline()->functions()->code("END_INLINE");
		#
#$prog->packages()->comment("End of package");
#$prog->packages()->close_block();
#$prog->prepare();
#ok ($prog->print(), qq~{\n    package My::Package;\n#Subroutines above...\n    #End of package\n}\n# BOOKMARK ---- My::Package\nuse Inline C => <<'END_INLINE'\n# BOOKMARK ---- apache_split\nAV* apache_split (SV* sv_inp, int numflds)\n{\n    register char *p;\n}\n# BOOKMARK ---- csv_split\nAV* csv_split (SV* sv_inp, int numflds)\n{\n    register char *p;\n}\nEND_INLINE\n~, 'deep print');
#ok ($prog->raw(), qq~{package My::Package;#Subroutines above...#End of package}# BOOKMARK ---- My::Packageuse Inline C => <<'END_INLINE'# BOOKMARK ---- apache_splitAV* apache_split (SV* sv_inp, int numflds){register char *p;}# BOOKMARK ---- csv_splitAV* csv_split (SV* sv_inp, int numflds){register char *p;}END_INLINE~, 'deep raw');
		#
#ok ($prog->exists('packages')->program_name(), 'packages', 'packages');
#ok ($prog->exists('inline')->exists('functions')->program_name(), 'functions', 'inline->functions');

sub csv_split
{
  my $c = shift;
  $c = $c->inline()->functions();
  $c->bookmark('csv_split');
  $c->code("AV* csv_split (SV* sv_inp, int numflds)");
  $c->open_block();
  $c->code("register char *p;");
  $c->close_block();
}
