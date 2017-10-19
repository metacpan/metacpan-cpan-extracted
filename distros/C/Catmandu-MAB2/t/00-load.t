use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catmandu::Importer::MAB2';
    use_ok 'Catmandu::Exporter::MAB2';
    use_ok 'Catmandu::Fix::mab_map';
    use_ok 'MAB2::Parser::Disk';
    use_ok 'MAB2::Parser::RAW';
    use_ok 'MAB2::Parser::XML';
    use_ok 'MAB2::Writer::RAW';
    use_ok 'MAB2::Writer::XML';

}

require_ok 'Catmandu::Importer::MAB2';
require_ok 'Catmandu::Exporter::MAB2';
require_ok 'Catmandu::Fix::mab_map';
require_ok 'MAB2::Parser::Disk';
require_ok 'MAB2::Parser::RAW';
require_ok 'MAB2::Parser::XML';
require_ok 'MAB2::Writer::RAW';
require_ok 'MAB2::Writer::XML';

done_testing;