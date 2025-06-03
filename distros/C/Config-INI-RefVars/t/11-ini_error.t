use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception lives_ok);
use Test::Warn;


use Config::INI::RefVars;

# use File::Spec::Functions qw(catdir catfile rel2abs splitpath);
#
# sub test_data_file { catfile(qw(t 11-data), $_[0]) }
#
# For heredocs containing INI data always use the single quote variant!
#

#
# Do not reuse the object in these tests, as it may be in an inconsistent
# state after the exception has been thrown!
#

subtest "section header" => sub {
  my $obj = Config::INI::RefVars->new();

  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                '[sec1]',
                                                'a=b',
                                                '[sec2'
                                               ]) },
       qr/'my INI': invalid section header at line 3\b/,
       "section header: the code died as expected");

  $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                '[sec1 ; ]  ; comment',
                                                '[sec2 # ] # comment',
                                                '',
                                                '[sec3 ; ] ; ] comment'  # sec3: invalid
                                               ]) },
       qr/'my INI': invalid section header at line 4\b/,
       "section header: the code died as expected");

  $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                '[sec1 ; ]  ; comment',
                                                '[sec2 # ] # comment',
                                                '',
                                                '[sec1 ; ] ; comment'  # valid but duplicate
                                               ]) },
       qr/'my INI': 'sec1 ;': duplicate header at line 4\b/,
       "section header: the code died as expected");

  $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                'a=b',
                                                '[__TOCOPY__]',
                                               ]) },
       qr/'my INI': tocopy section '__TOCOPY__' must be first section at line 2\b/,
       "section header: the code died as expected");

  $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src_name       => "my INI",
                                   tocopy_section => 'CommSec',
                                   src            => [
                                                      'a=b',
                                                      '[CommSec]',
                                                     ]) },
       qr/'my INI': tocopy section 'CommSec' must be first section at line 2\b/,
       "section header: the code died as expected");

  $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src_name => "my INI",
                                   src      => [
                                                '[sec]',
                                                'a=b',
                                                '[__TOCOPY__]',
                                               ]) },
       qr/'my INI': tocopy section '__TOCOPY__' must be first section at line 3\b/,
       "section header: the code died as expected");
};

subtest "var def" => sub {
  my $obj = Config::INI::RefVars->new();

  like(exception { $obj->parse_ini(src => [
                                           '[sec]',
                                           'a',
                                           '[__TOCOPY__]',
                                          ]) },
       qr/'INI data': neither section header nor key definition at line 2\b/,
       "var def: the code died as expected");

  $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src => [
                                           '[sec]',
                                           '.?()+. = a value',
                                           '  = another value',    # note the heading blanks!
                                          ]) },
       qr/'INI data': empty variable name at line 3\b/,
       "var def: the code died as expected");

  $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src => [
                                           '[sec]',
                                           '.?()+. = a value',
                                           '.?()+.= another value',
                                          ]) },
       qr/'INI data': empty variable name at line 3\b/,
       "var def: the code died as expected");
};


subtest "var refs" => sub {
  my $obj = Config::INI::RefVars->new();

  subtest "unterminated variable reference" => sub {
    like(exception { $obj->parse_ini(src => [
                                             '[sec]',
                                             'a.=$(b'
                                            ]) },
         qr/'\[sec\]a': unterminated variable reference/,
         "var ref: the code died as expected");

    $obj = Config::INI::RefVars->new();
    like(exception { $obj->parse_ini(src => [
                                             '[sec]',
                                             'a.=$()$(f($(o)$(b)$(x$($(foobar$(=)))',
                                             'b=42'
                                            ]) },
         qr/'\[sec\]a': unterminated variable reference/,
         "var ref: the code died as expected");
  };

  $obj = Config::INI::RefVars->new();
  subtest "variable references itself" => sub {
    like(exception { $obj->parse_ini(src => [
                                             '[sec]',
                                             'a.=$(a)'
                                            ]) },
         qr/recursive variable '\[sec\]a' references itself/,
         "var ref: the code died as expected");

    $obj = Config::INI::RefVars->new();
    like(exception { $obj->parse_ini(src => [
                                             '[sec]',
                                             '',
                                             'x=$(y)',
                                             'y=$(z)',
                                             'z=$(x)',
                                            ]) },
         qr/recursive variable '\[sec\][xyz]' references itself/,
         "var ref: the code died as expected");

    $obj = Config::INI::RefVars->new();
    like(exception { $obj->parse_ini(src => [
                                             '[000]',
                                             'a:=$(z)',
                                             'z:=$([001]x)',
                                             '',
                                             '[001]',
                                             'x=$([002]x)',
                                             '',
                                             '[002]',
                                             'x=$([001]x)',
                                            ]) },
         qr/recursive variable '\[00[12]\]x' references itself/,
         "var ref: the code died as expected");
  };
};



subtest "no directives" => sub {
  note(
       "TEST MUST BE REMOVED OR CHANGED AS SOON AS THE FIRST DIRECTIVES ARE IMPLEMENTED"
      );
  my $obj = Config::INI::RefVars->new();

  like(exception { $obj->parse_ini(src => [
                                           '[sec]',
                                           '  ;!',
                                           '=a',
                                           ]) },
         qr/'INI data': directives are not yet supported at line 3\b/,
         "no directives: the code died as expected");

  $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src => [
                                           '[sec]',
                                           ';!',
                                           ]) },
         qr/'INI data': directives are not yet supported at line 2\b/,
         "no directives: the code died as expected");
};


subtest "unsupported modifier" => sub {
  my $obj = Config::INI::RefVars->new();
  like(exception { $obj->parse_ini(src => [
                                           '[sec]',
                                           'x++...!!!&&&&=a',
                                           ]) },
         qr/'INI data': '\+\+\.\.\.!!!&&&&': unsupported modifier at line 2\b/,
         "no directives: the code died as expected");
};

subtest "varname_chk_re" => sub {
  my $obj = Config::INI::RefVars->new(varname_chk_re => qr/^[A-Z]/);
  subtest "All var names match" => sub {
    my $src = [ '[the section]',
                ' A=the value',
                'Xyz=123',
                'Z1=z2',
                'Y=',
              ];
    lives_ok {$obj->parse_ini(src => $src)} 'varname_chk_re: code does not fail';
  };
  subtest "A var name does not match" => sub {
    my $src = <<'EOT';

      [the section]
      A=the value
      xYZ=123
      Z1=z2
      Y=
EOT

    like(exception { $obj->parse_ini(src => $src)},
         qr/'xYZ': var name does not match varname_chk_re/,
         "varname_chk_re: the code died as expected"
        );
  };
};


#==================================================================================================
done_testing();

