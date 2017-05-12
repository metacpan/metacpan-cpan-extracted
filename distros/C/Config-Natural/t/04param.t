use strict;
use Test;
BEGIN { plan tests => 33 }
use Config::Natural;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

# there must be no param
ok( $obj->param, 0 );  #01

# these params are not defined
ok( not defined $obj->param('') );  #02
ok( not defined $obj->param('Adam') );  #03

# affecting a param (Tk-style), then checking it's there
$obj->param(-shito_3 => 'Sachiel');
ok( $obj->param('shito_3'), 'Sachiel');  #04

# affecting a param (hashref), then checking it's there
$obj->param({shito_5 => 'Ramiel'});
ok( $obj->param('shito_5'), 'Ramiel');  #05

# there must be two params
ok( $obj->param == 2 );  #06

# affecting three params (Tk-style), then checking they're there
$obj->param(-shito_4 => 'Samsiel', -shito_6 => 'Gagiel', -shito_8 => 'Sandalfon');
my @p = $obj->param(qw(shito_4 shito_6 shito_8));
ok( $p[0], 'Samsiel'   );   #07
ok( $p[1], 'Gagiel'    );   #08
ok( $p[2], 'Sandalfon' );   #09

# affecting three params (hashref), then checking they're there
$obj->param({shito_7 => 'Israfel', shito_9 => 'Matarael', shito_10 => 'Saraqiel'});
@p = $obj->param(qw(shito_7 shito_9 shito_10));
ok( $p[0], 'Israfel'   );   #10
ok( $p[1], 'Matarael'  );   #11
ok( $p[2], 'Saraqiel'  );   #12

# affecting some params (Tk-style) while reading the value of others
@p = $obj->param('shito_7', -shito_11 => 'Iroel', 'shito_5', -shito_12 => 'Leliel');
ok( $p[0], 'Israfel'   );   #13
ok( $p[1], 'Ramiel'    );   #14

# affecting some params (hashref) while reading the value of others
@p = $obj->param('shito_9', {shito_13 => 'Bardiel'}, 'shito_3', {shito_14 => 'Zeruel'});
ok( $p[0], 'Matarael'  );   #15
ok( $p[1], 'Sachiel'   );   #16
ok( $obj->param('shito_13'), 'Bardiel' );  #17
ok( $obj->param('shito_14'), 'Zeruel'  );  #18

# affecting some params (both styles) while reading the value of others
@p = $obj->param('shito_14', -shito_15 => 'Arael', 'shito_10', 
     {shito_16 => 'Armisael', shito_17 => 'Tabris'}, 'shito_6');
ok( $p[0] eq 'Zeruel'   );  #19
ok( $p[1] eq 'Saraqiel' );  #20
ok( $p[2] eq 'Gagiel'   );  #21
ok( $obj->param('shito_15') eq 'Arael'    );  #22
ok( $obj->param('shito_16') eq 'Armisael' );  #23
ok( $obj->param('shito_17') eq 'Tabris'   );  #24


# now clearing a parameter
$obj->clear('shito_1');
ok( $obj->param('shito_1'),  '' );  #25

# now clearing a list of parameters
$obj->clear(qw(shito_2 shito_3 shito_4 shito_5));
ok( $obj->param('shito_2'),  '' );  #26
ok( $obj->param('shito_3'),  '' );  #27
ok( $obj->param('shito_4'),  '' );  #28
ok( $obj->param('shito_5'),  '' );  #29

# now clearing all parameters
$obj->clear_params;
ok( $obj->param('shito_6'),  '' );  #30
ok( $obj->param('shito_9'),  '' );  #31
ok( $obj->param('shito_13'), '' );  #32
ok( $obj->param('shito_17'), '' );  #33

