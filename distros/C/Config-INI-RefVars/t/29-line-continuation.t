use strict;
use warnings;

use Test::More;
use Config::INI::RefVars;

use Test::Exception;

use lib 't';

use Local::Test::RefVars qw(write_file);

use File::Temp qw(tempdir);

subtest 'Line continuation' => sub {
  my $ini = <<'END_INI';
[my section]
single = one\

multi \= foo\
  bar\
  baz

space before backslash \= this line \
that line

expand :\= $(multi)\
!

append +\= abc\
def

normal = x\
y = separate

last \= last line\
END_INI

  subtest 'with trailing newline' => sub {
    $ini =~ /\s+\z/ or die("No white chars at end of input"); # just to be sure
    my $parser = Config::INI::RefVars->new();
    my $vars = $parser->parse_ini(src => $ini)->variables()->{'my section'};

    is($vars->{single}, 'one\\',
       'ordinary assignment does not use continuation');
    is($vars->{multi}, 'foo  bar  baz',
       'continued assignment');
    is($vars->{'space before backslash'}, 'this line that line',
       'space before backslash');
    is($vars->{expand}, 'foo  bar  baz!',
       'continuation also works with := assignments');
    is($vars->{append}, 'abcdef',
       'continuation also works with += assignments');
    is($vars->{normal}, 'x\\',
       'continuation is disabled unless modifier contains backslash');
    is($vars->{y}, 'separate',
       'following line is parsed as separate assignment');
    is($vars->{last}, 'last line',
       'continuation stops cleanly at end of file');
  };

  subtest 'without trailing newline' => sub {
    chomp($ini);
    my $parser = Config::INI::RefVars->new();
    my $vars = $parser->parse_ini(src => $ini)->variables()->{'my section'};

    # In this case, it's enough to check the last line.
    is($vars->{last}, 'last line', 'continuation stops cleanly at end of file');
  };
};


subtest 'Line continuation edge cases' => sub {
  my $ini = <<'END_INI';
[my section]
a \= abc\
def\
ghi

b \= xyz\
END_INI

  my $parser = Config::INI::RefVars->new;
  my $vars = $parser->parse_ini(src => $ini)->variables()->{'my section'};

  is($vars->{a}, 'abcdefghi', 'multiple continuation lines');
  is($vars->{b}, 'xyz', 'EOF after trailing backslash');
};


subtest "'=include' directive in line continuation" => sub {
  my $dir = tempdir(CLEANUP => 1);
  write_file(
    File::Spec->catfile($dir, "main.ini"),
             <<'END');
text \= abc\
=include foo.ini
END

  throws_ok {
    Config::INI::RefVars->new->parse_ini(src => File::Spec->catfile($dir, "main.ini"));
  }
  qr/directive in line continuation/i,
    'directive not allowed inside line continuation';
};


subtest 'directive in line continuation' => sub {

  my $dir = tempdir(CLEANUP => 1);

  write_file(
    File::Spec->catfile($dir, "main.ini"),
             <<'END');
text \= abc\
=
END

  throws_ok {
    Config::INI::RefVars->new->parse_ini(src => File::Spec->catfile($dir, "main.ini"));
  }
  qr/directive in line continuation/i,
    'directive not allowed inside line continuation';
};


subtest 'equal sign inside continuation text (with $())' => sub {
  my $dir = tempdir(CLEANUP => 1);
  write_file(File::Spec->catfile($dir, "main.ini"),
             <<'END');
[sec]
text \= abc\
$()=include foo.ini
END

  my $vars =
    Config::INI::RefVars->new->parse_ini(src =>
                                         File::Spec->catfile($dir, "main.ini")) ->variables;

  is($vars->{sec}{text}, 'abc=include foo.ini',
     'only a physical line beginning with "=" is treated as a directive');
};


subtest 'equal sign inside continuation text (with heading space)' => sub {
  my $dir = tempdir(CLEANUP => 1);
  write_file(File::Spec->catfile($dir, "main.ini"),
             <<'END');
[sec]
text \= abc\
 = blah blah
END

  my $vars =
    Config::INI::RefVars->new->parse_ini(src =>
                                         File::Spec->catfile($dir, "main.ini")) ->variables;

  is($vars->{sec}{text}, 'abc = blah blah',
     'only a physical line beginning with "=" is treated as a directive');
};


#==================================================================================================
done_testing;
