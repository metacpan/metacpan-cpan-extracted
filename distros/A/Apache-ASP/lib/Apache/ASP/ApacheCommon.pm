package Apache::ASP::ApacheCommon;

eval {
    # Try new Apache2 module requests first
    require Apache2::RequestRec;
    require Apache2::RequestUtil;
    require Apache2::RequestIO;
    require Apache2::Response;
    require APR::Table;
    require APR::Pool;
    require Apache2::Connection;
    require Apache2::ServerUtil;
    require Apache2::ServerRec;
    require Apache2::SubRequest;
    require Apache2::Log;
};

# per Warren Young, to work with mod_perls of 1.99_07 and _09 vintage
if($@) {
    eval {
	# Alternative if above fails because system is old, but not
	# so old that it's incompatible.
	require Apache::RequestRec;
	require Apache::RequestUtil;
	require Apache::RequestIO;
	require Apache::Response;
	require APR::Table;
	require APR::Pool;
	require Apache::Connection;
	require Apache::ServerUtil;
	require Apache::SubRequest;
	require Apache::Log;
    };
}

1;
