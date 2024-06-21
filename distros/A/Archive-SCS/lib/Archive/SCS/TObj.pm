use v5.28;
use warnings;
use Object::Pad 0.73;

class Archive::SCS::TObj 1.04;

field $meta  :param;
field $data  :param;

method _meta () {$meta}

method dds () {$data}

method tobj () {}

1;
