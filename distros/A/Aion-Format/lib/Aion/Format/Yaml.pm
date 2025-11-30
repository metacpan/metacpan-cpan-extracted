package Aion::Format::Yaml;

use common::sense;
use YAML::Syck qw//;

use Exporter qw/import/;
our @EXPORT = our @EXPORT_OK = grep {
    *{$Aion::Format::Yaml::{$_}}{CODE} && !/^(_|(NaN|import)\z)/n
} keys %Aion::Format::Yaml::;

#@category yaml

# Настраиваем yaml
$YAML::Syck::Headless = 1;
$YAML::Syck::SortKeys = 1;
$YAML::Syck::ImplicitTyping = 1;
$YAML::Syck::ImplicitUnicode = 1;
$YAML::Syck::ImplicitBinary = 1;
$YAML::Syck::UseCode = 1;
$YAML::Syck::LoadCode = 1;
$YAML::Syck::DumpCode = 1;

# В yaml
sub to_yaml(;$) {
	YAML::Syck::Dump(@_ == 0? $_: @_)
}

# Из yaml
sub from_yaml(;$) {
	scalar YAML::Syck::Load(@_ == 0? $_: @_)
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Format::Yaml - converter from/to yaml

=head1 SYNOPSIS

	use Aion::Format::Yaml qw/from_yaml to_yaml/;
	
	to_yaml {foo => 'bar'} # -> "foo: bar\n"
	from_yaml "a: b" # --> {a => "b"}

=head1 DESCRIPTION

Converts from/to yaml. Under the hood it uses C<YAML::Syck>, customized to Aion's requirements.

=head1 SUBROUTINES

=head2 to_yaml ($struct)

In yaml.

	to_yaml {foo => undef} # => foo: ~\n
	to_yaml {foo => 'true'} # => foo: 'true'\n

=head2 from_yaml ($string)

From yaml.

Boolean values:

	y|Y|yes|Yes|YES|n|N|no|No|NO|
	true|True|TRUE|false|False|FALSE|
	on|On|ON|off|Off|OFF



	from_yaml "a: true" # --> {a => 1}
	from_yaml "a: yes" # --> {a => 1}
	from_yaml "a: y" # --> {a => 1}
	from_yaml "a: ON" # --> {a => 1}
	from_yaml "a: FALSE" # --> {a => ""}
	from_yaml "a: No" # --> {a => ""}
	from_yaml "a: N" # --> {a => ""}
	from_yaml "a: off" # --> {a => ""}

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Format::Yaml module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
