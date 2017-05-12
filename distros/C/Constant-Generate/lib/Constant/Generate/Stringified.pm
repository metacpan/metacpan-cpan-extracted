package Constant::Generate::Stringified;
require Constant::Generate::Dualvar;

sub import {
    goto &Constant::Generate::Dualvar::import;
}

1;