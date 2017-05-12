(  
    job_name    => 'phyml',
    tmp_dir    => 'tmp',
    result_dir => 'result',
    stderr_dir => 'tmp/error',
    stdout_dir => 'tmp/output',
    type       => 'aa',

    input => [ { format => 'general', sep => '^>', files => [ ...] }, '...'],
    mode => 'AvsB',
    parts  => 3,
);
