use Test::Most 0.22 qw(no_plan);
use Test::NoWarnings;
use App::Config::Chronicle::Attribute::Section;

my $section = App::Config::Chronicle::Attribute::Section->new(
    name        => 'test',
    parent_path => 'apperturescience',
    definition  => {},
    data_set    => {},
);
ok $section, 'Section Created';

is $section->path, 'apperturescience.test', 'Test Chamber created';

$section->meta->make_mutable;
$section->meta->add_attribute(
    'cubes',
    is     => 'ro',
    isa    => 'Int',
    writer => '_cubes',
);

lives_ok {
    $section->_cubes(12);
}
'Able to set created Attrubute';
