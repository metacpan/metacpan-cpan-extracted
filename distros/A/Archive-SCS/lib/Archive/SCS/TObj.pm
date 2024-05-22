use v5.38;
use feature 'class';
no warnings 'experimental::class';

class Archive::SCS::TObj 0.02;

field $meta  :param;
field $data  :param;

method _meta () {$meta}

method dds () {$data}

method tobj () {}
