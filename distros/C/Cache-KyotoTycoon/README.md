# NAME

Cache::KyotoTycoon - KyotoTycoon client library

# SYNOPSIS

    use Cache::KyotoTycoon;

    my $kt = Cache::KyotoTycoon->new(host => '127.0.0.1', port => 1978);
    $kt->set('foo' => bar');
    $kt->get('foo'); # => 'bar'

# DESCRIPTION

KyotoTycoon.pm is [KyotoTycoon](http://fallabs.com/kyototycoon/) client library for Perl5.

**THIS MODULE IS IN ITS BETA QUALITY. THE API MAY CHANGE IN THE FUTURE**.

# ERROR HANDLING POLICY

This module throws exception if got **Server Error**.

# CONSTRUCTOR OPTIONS

- `timeout`

    Timeout value for each request in seconds.

    _Default_: 1 second

- `host`

    Host name of server machine.

    _Default_: '127.0.0.1'

- `port`

    Port number of server process. 

    _Default_: 1978 

- `db`

    DB name or id.

    _Default_: 0

# METHODS

- `$kt->db()`

    Getter/Setter of DB name/id.

- `my $cursor: Cache::KyotoTycoon::Cursor = $kt->make_cursor($cursor_number: Int);`

    Create new cursor object. This method returns instance of [Cache::KyotoTycoon::Cursor](https://metacpan.org/pod/Cache::KyotoTycoon::Cursor).

- `my $res = $kt->echo($args)`

    The server returns $args. This method is useful for testing server.

    $args is hashref.

    _Return_: the copy of $args.

- `$kt->report()`

    Get server report.

    _Return_: server status information in hashref.

- `my $output = $kt->play_script($name[, \%input]);`

    Call a procedure of the script language extension.

    _$name_: the name of the procedure to call.
    _\\%input_: (optional): arbitrary records.

    _Return_: response of the script in hashref.

- `my $info = $kt->status()`

    Get database status information.

    _Return_: database status information in hashref.

- `$kt->clear()`

    Remove all elements for the storage.

    _Return_: Not a useful value.

- `$kt->synchronize($hard:Bool, $command);`

    Synchronize database with file system.

    _$hard_: call fsync() or not.

    _$command_: call $command in synchronization state.

    _Return_: 1 if succeeded, 0 if $command returns false.

- `$kt->set($key, $value, $xt);`

    Store _$value_ to _$key_.

    _$xt_: expiration time. If $xt>0, expiration time in seconds from now. If $xt<0, the epoch time. It is never remove if missing $xt.

    _Return_: not a useful value.

- `my $ret = $kt->add($key, $value, $xt);`

    Store record. This method is not store if the _$key_ is already in the database.

    _$xt_: expiration time. If $xt>0, expiration time in seconds from now. If $xt<0, the epoch time. It is never remove if missing $xt.

    _Return_: 1 if succeeded. 0 if $key is already in the db.

- `my $ret = $kt->replace($key, $value, $xt);`

    Store the record, ignore if the record is not exists in the database.

    _$xt_: expiration time. If $xt>0, expiration time in seconds from now. If $xt<0, the epoch time. It is never remove if missing $xt.

    _Return_: 1 if succeeded. 0 if $key is not exists in the database.

- `my $ret = $kt->append($key, $value, $xt);`

    Store the record, append the $value to existent record if already exists entry.

    _$xt_: expiration time. If $xt>0, expiration time in seconds from now. If $xt<0, the epoch time. It is never remove if missing $xt.

    _Return_: not useful value. 

- `my $ret = $kt->increment($key, $num, $xt);`

    _$num_: incremental

    _Return_: value after increment. 

- `my $ret = $kt->increment_double($key, $num, $xt);`

    _$num_: incremental

    _Return_: value after increment. 

- `my $ret = $kt->cas($key, $oval, $nval, $xt);`

    compare and swap.

    _$oval_: old value
    _$nval_: new value

    _Return_: 1 if succeeded, 0 if failed.

- `$kt->remove($key);`

    Remove _$key_ from database.

    _Return_ 1 if removed, 0 if record does not exists.

- `my $val = $kt->get($key);`

    Get _$key_ from database.

    _Return_: the value from database in scalar context. ($value, $xt) in list context. _undef_ or empty list  if not exists in database.

- `$kt->set_bulk(\%values);`

    Store multiple values in one time.

    _Return_: not useful value.

- `$kt->remove_bulk(\@keys);`

    Remove multiple keys in one time.

    _Return_: not useful value.

- `my $hashref = $kt->get_bulk(\@keys);`

    Get multiple values in one time.

    _Return_: records in hashref.

- `$kt->vacuum([$step]);`

    Scan the database and eliminate regions of expired records.

    _input_: step: (optional): the number of steps. If it is omitted or not more than 0, the whole region is scanned.

    _Return_: not useful.

- `my $hashref = $kt->match_prefix($prefix, $max);`

    Get list of matching keys.

    _Return_: records in hashref.

- `my $hashref = $kt->match_regex($regex, $max);`

    Get list of matching keys.

    _Return_: records in hashref.

- `my $hashref = $kt->match_similar($origin, $range, $utf8, $max);`

    Get list of matching keys.

    _Return_: records in hashref.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

- `[KyotoTycoon](http://fallabs.com/kyototycoon/)`
- `http://fallabs.com/mikio/tech/promenade.cgi?id=99`

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
