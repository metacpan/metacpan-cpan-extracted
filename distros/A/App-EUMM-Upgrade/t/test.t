#!perl

use strict;
use warnings;
use App::EUMM::Upgrade;
use Test::More 0.88; # tests => 4

{
my $text=<<'EOT';
		MIN_PERL_VERSION => 5.004,
		META_MERGE => {
			resources => {
				repository => '',
			},
		},
EOT

my $text1=<<'EOT';
	MIN_PERL_VERSION => 5.004,
	META_MERGE => {
		resources => {
			repository => '',
		},
	},
EOT
is(App::EUMM::Upgrade::_unindent("\t",$text),$text1, '_unindent');

}

{
my $text=<<'EOT';
WriteMakefile(
	VERSION   => $VERSION,
	($] >= 5.005 ? (
		AUTHOR  => '***',
	) : ()),
);
EOT

my $text1=<<'EOT';
WriteMakefile(
	VERSION   => $VERSION,
	AUTHOR  => '***',
);
EOT
is(App::EUMM::Upgrade::remove_conditional_code($text,"\t"),$text1);

}

{
my $text=<<'EOT';
	($ExtUtils::MakeMaker::VERSION ge '6.31' ? (
		LICENSE => 'perl',
	) : ()),
EOT

my $text1=<<'EOT';
	LICENSE => 'perl',
EOT
is(App::EUMM::Upgrade::remove_conditional_code($text,"\t"),$text1);

}

{
my $text=<<'EOT';
  ($ExtUtils::MakeMaker::VERSION gt '6.30'?
   (LICENSE => 'perl', ) : ()),
EOT

my $text1=<<'EOT';
  LICENSE => 'perl',
EOT
is(App::EUMM::Upgrade::remove_conditional_code($text,"  "),$text1);

}

{
my $text=<<'EOT';
	($ExtUtils::MakeMaker::VERSION ge '6.48' ? (
		MIN_PERL_VERSION => 5.004,
		META_MERGE => {
			resources => {
				repository => '',
			},
		},
	) : ()),
EOT

my $text1=<<'EOT';
	MIN_PERL_VERSION => 5.004,
	META_MERGE => {
		resources => {
			repository => '',
		},
	},
EOT
is(App::EUMM::Upgrade::remove_conditional_code($text,"\t"),$text1);

}

{
my $text=<<'EOT';
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
EOT

my $text1=<<'EOT';
  LICENSE => 'perl'
EOT
is(App::EUMM::Upgrade::remove_conditional_code($text,"  "),$text1);

}


{
my $text=<<'EOT';
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
EOT

my $text1=<<'EOT';
  LICENSE => 'perl'
EOT
is(App::EUMM::Upgrade::remove_conditional_code($text,"  "),$text1);

}


{
my $text=<<'EOT';
    ($] >= 5.005 ?
       (AUTHOR         => '***') : ()),
EOT

my $text1=<<'EOT';
    AUTHOR         => '***',
EOT
is(App::EUMM::Upgrade::remove_conditional_code($text,"  "),$text1);

}

{
my $text=<<'EOT';
    ($] >= 5.005 ?
       (AUTHOR         => '***',) : ()),
EOT

my $text1=<<'EOT';
    AUTHOR         => '***',
EOT
is(App::EUMM::Upgrade::remove_conditional_code($text,"  "),$text1);

}

{
my $text=<<'EOT';
 aaa
   bbb
EOT

my $text1=<<'EOT';
  aaa
      bbb
EOT
is(App::EUMM::Upgrade::apply_indent($text,1,2),$text1, 'apply_indent');

}

{
my $text=<<'EOT';
WriteMakefile(
  "ABSTRACT" => "Test abstract",
);
EOT

my $text1=<<'EOT';
WriteMakefile(TEST => 'test',
  "ABSTRACT" => "Test abstract",
);
EOT
is(App::EUMM::Upgrade::add_new_fields($text,"TEST => 'test',"),$text1, 'add_new_fields');

}

{
my $text=<<'EOT';
my %WriteMakefileArgs = (
  "ABSTRACT" => "Test abstract",
);
WriteMakefile(%WriteMakefileArgs);
EOT

my $text1=<<'EOT';
my %WriteMakefileArgs = (TEST => 'test',
  "ABSTRACT" => "Test abstract",
);
WriteMakefile(%WriteMakefileArgs);
EOT
is(App::EUMM::Upgrade::add_new_fields($text,"TEST => 'test',"),$text1, 'add_new_fields');

}

=for cmt


=cut

done_testing;
