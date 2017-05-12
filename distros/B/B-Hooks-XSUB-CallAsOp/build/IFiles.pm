package B::Hooks::XSUB::CallAsOp::Install::Files;

$self = {
          'inc' => '',
          'typemaps' => [],
          'deps' => [],
          'libs' => ''
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/B/Hooks/XSUB/CallAsOp/Install/Files.pm") {
			$CORE = $_ . "/B/Hooks/XSUB/CallAsOp/Install/";
			last;
		}
	}

1;
