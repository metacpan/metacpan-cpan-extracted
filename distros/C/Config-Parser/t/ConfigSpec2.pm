package ConfigSpec2;
use parent 'TestConfig';

1;
__DATA__
[core]
    base = STRING :mandatory null    
[load ANY param]
    __options__ = :mandatory
    mode = OCTAL
    owner = STRING
