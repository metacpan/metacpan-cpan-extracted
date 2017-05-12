use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'AI::Genetic::Pro',
    AUTHOR        => 'Lukasz Strzelecki <strzelec@rswsystems.pl>',
    VERSION_FROM  => 'lib/AI/Genetic/Pro.pm',
    ABSTRACT_FROM => 'lib/AI/Genetic/Pro.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'UNIVERSAL::require'		=> 0,
        'Carp'						=> 0,
		'Struct::Compare'			=> 0,
        'Exporter::Lite'			=> 0,
        'Tie::Array::Packed'		=> 0,
		'List::Util'				=> 0,
		'List::MoreUtils'			=> 0,
		'Clone'						=> 0,
		'Math::Random'				=> 0,
		'Digest::MD5'				=> 0,
		'Class::Accessor::Fast::XS'	=> 0,
		'Storable'					=> 2.05,
		'GD::Graph::linespoints'	=> 0,
    },
);
