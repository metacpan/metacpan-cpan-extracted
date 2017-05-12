# colorizer matching rules for sb
[
  qr{Starting (\w+)\.\.\.}, 
  [ qw( startup appname ) ],

  qr{Nginx is running on: (http://([0-9.]+):([0-9]+)/)},
  [ qw( startup url ip port ) ],

  qr{\s+\* Running with SSL on port ([0-9]+)\.},
  [ qw( startup port ) ],

  qr{(\[([^\]]+)\]) (\[([^\]]+)\]) (\[([^\]]+)\]) (\[([^\]]+)\]) (\[([^\]]+)\]) (\[([^\]]+)\]) (\[([^\]]+)\]).*},
  [ qw( message group timestamp group hostname group username group ip group time group url group status ) ],

  qr{refresh file .*},
  [ qw( refresh ) ],

  qr{StatINC: process \d+ reloading .*},
  [ qw( refresh ) ],
  
  qr{Subroutine (\S+) redefined at (\S+) line (\d+)(?:, (<DATA>) line (\d+))?\.},
  [ qw( refresh code file line filehandle line ) ],

  qr{Subroutine (\S+) redefined at (\S+) line (\d+)\..*},
  [ qw( refresh code file line filehandle line ) ],

  qr{(.*?) called at (\S+) line (\d+)},
  [ qw( message code file line ) ],

  qr{(.*?) called at (\(eval \d\)) line (\d+)},
  [ qw( message code evalnumber line ) ],

  qr{(.*?) at (\S+) line (\d+)\."?},
  [ qw( message error file line ) ],

  qr{(.*?) at (\S+) line (\d+), at (?:EOF|end of line)},
  [ qw( message error file line ) ],
  
  qr{(.*?) at (\(eval \d\)) line (\d+)\."?},
  [ qw( message error evalnumber line ) ],
];
