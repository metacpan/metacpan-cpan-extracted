# colorizer matching rules for sb
ruleset {
    rule qr{Starting (\w+)\.\.\.}, qw(
        startup appname
    );

    rule qr{Nginx is running on: (http://([0-9.]+):([0-9]+)/)}, qw( 
        startup url ip port 
    );

    rule qr{\s+\* Running with SSL on port ([0-9]+)\.}, qw( 
        startup port 
    );

    rule qr{(\[([^\]]+)\]) (\[([^\]]+)\]) (\[([^\]]+)\]) (\[([^\]]+)\]) (\[([^\]]+)\]) (\[([^\]]+)\]) (\[([^\]]+)\]).*}, qw( 
        message group timestamp 
                group hostname 
                group username 
                group ip 
                group time 
                group url 
                group status 
    );

    rule qr{(.*?) called at (\S+) line (\d+)}, qw( 
        message code file line
    );

    rule qr{(.*?) called at (\(eval \d\)) line (\d+)}, qw(
        message code evalnumber line 
    );

    rule qr{(.*?) at (\S+) line (\d+)\."?}, qw(
        message error file line 
    );

    rule qr{(.*?) at (\S+) line (\d+), at (?:EOF|end of line)}, qw(
        message error file line 
    );
  
    rule qr{(.*?) at (\(eval \d\)) line (\d+)\."?}, qw( 
        message error evalnumber line 
    );
}
