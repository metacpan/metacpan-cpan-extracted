# -*- coding: utf-8 -*-


package t::lib::Crane::Logger;


use Crane::Base qw( Exporter );
use Crane::Logger qw( :DEFAULT :levels );

use Test::More;


our @EXPORT = qw(
    &test_fatal
    &test_error
    &test_warning
    &test_info
    &test_debug
    &test_verbose
);


my $FATAL_RE = qr{\[[^\]]+\] Fatal}si;
my $ERROR_RE = qr{\[[^\]]+\] Error}si;
my $WARNING_RE = qr{\[[^\]]+\] Warning}si;
my $INFO_RE = qr{\[[^\]]+\] Info}si;
my $DEBUG_RE = qr{\[[^\]]+\] Debug}si;
my $VERBOSE_RE = qr{\[[^\]]+\] Verbose}si;


sub log_messages {
    
    my ( $level ) = @_;
    
    my $messages_filename = 'messages.log';
    my $errors_filename = 'errors.log';
    
    open my $messages_fh, '>:encoding(UTF-8)', $messages_filename or confess($OS_ERROR);
    open my $errors_fh, '>:encoding(UTF-8)', $errors_filename or confess($OS_ERROR);
    
    local $Crane::Logger::LOG_LEVEL = $level;
    local $Crane::Logger::MESSAGES_FH = $messages_fh;
    local $Crane::Logger::ERRORS_FH = $errors_fh;
    
    log_fatal('Fatal');
    log_error('Error');
    log_warning('Warning');
    log_info('Info');
    log_debug('Debug');
    log_verbose('Verbose');
    
    local $INPUT_RECORD_SEPARATOR = undef;
    
    close $messages_fh or confess($OS_ERROR);
    close $errors_fh or confess($OS_ERROR);
    
    open $messages_fh, '<:encoding(UTF-8)', $messages_filename or confess($OS_ERROR);
    open $errors_fh, '<:encoding(UTF-8)', $errors_filename or confess($OS_ERROR);
    
    my $messages = <$messages_fh>;
    my $errors = <$errors_fh>;
    
    close $messages_fh or confess($OS_ERROR);
    close $errors_fh or confess($OS_ERROR);
    
    unlink $messages_filename;
    unlink $errors_filename;
    
    return ( $messages, $errors );
    
}


sub test_fatal {
    
    plan('tests' => 2);
    
    subtest('Messages' => \&test_fatal_messages);
    subtest('Errors' => \&test_fatal_errors);
    
    return done_testing();
    
}


sub test_fatal_messages {
    
    plan('tests' => 6);
    
    my ( $messages, undef ) = log_messages($LOG_FATAL);
    
    unlike($messages, $FATAL_RE, 'Fatal');
    unlike($messages, $ERROR_RE, 'Error');
    unlike($messages, $WARNING_RE, 'Warning');
    unlike($messages, $INFO_RE, 'Info');
    unlike($messages, $DEBUG_RE, 'Debug');
    unlike($messages, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_fatal_errors {
    
    plan('tests' => 6);
    
    my ( undef, $errors ) = log_messages($LOG_FATAL);
    
    like($errors, $FATAL_RE, 'Fatal');
    unlike($errors, $ERROR_RE, 'Error');
    unlike($errors, $WARNING_RE, 'Warning');
    unlike($errors, $INFO_RE, 'Info');
    unlike($errors, $DEBUG_RE, 'Debug');
    unlike($errors, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_error {
    
    plan('tests' => 2);
    
    subtest('Messages' => \&test_error_messages);
    subtest('Errors' => \&test_error_errors);
    
    return done_testing();
    
}


sub test_error_messages {
    
    plan('tests' => 6);
    
    my ( $messages, undef ) = log_messages($LOG_ERROR);
    
    unlike($messages, $FATAL_RE, 'Fatal');
    unlike($messages, $ERROR_RE, 'Error');
    unlike($messages, $WARNING_RE, 'Warning');
    unlike($messages, $INFO_RE, 'Info');
    unlike($messages, $DEBUG_RE, 'Debug');
    unlike($messages, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_error_errors {
    
    plan('tests' => 6);
    
    my ( undef, $errors ) = log_messages($LOG_ERROR);
    
    like($errors, $FATAL_RE, 'Fatal');
    like($errors, $ERROR_RE, 'Error');
    unlike($errors, $WARNING_RE, 'Warning');
    unlike($errors, $INFO_RE, 'Info');
    unlike($errors, $DEBUG_RE, 'Debug');
    unlike($errors, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_warning {
    
    plan('tests' => 2);
    
    subtest('Messages' => \&test_warning_messages);
    subtest('Errors' => \&test_warning_errors);
    
    return done_testing();
    
}


sub test_warning_messages {
    
    plan('tests' => 6);
    
    my ( $messages, undef ) = log_messages($LOG_WARNING);
    
    unlike($messages, $FATAL_RE, 'Fatal');
    unlike($messages, $ERROR_RE, 'Error');
    unlike($messages, $WARNING_RE, 'Warning');
    unlike($messages, $INFO_RE, 'Info');
    unlike($messages, $DEBUG_RE, 'Debug');
    unlike($messages, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_warning_errors {
    
    plan('tests' => 6);
    
    my ( undef, $errors ) = log_messages($LOG_WARNING);
    
    like($errors, $FATAL_RE, 'Fatal');
    like($errors, $ERROR_RE, 'Error');
    like($errors, $WARNING_RE, 'Warning');
    unlike($errors, $INFO_RE, 'Info');
    unlike($errors, $DEBUG_RE, 'Debug');
    unlike($errors, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_info {
    
    plan('tests' => 2);
    
    subtest('Messages' => \&test_info_messages);
    subtest('Errors' => \&test_info_errors);
    
    return done_testing();
    
}


sub test_info_messages {
    
    plan('tests' => 6);
    
    my ( $messages, undef ) = log_messages($LOG_INFO);
    
    unlike($messages, $FATAL_RE, 'Fatal');
    unlike($messages, $ERROR_RE, 'Error');
    unlike($messages, $WARNING_RE, 'Warning');
    like($messages, $INFO_RE, 'Info');
    unlike($messages, $DEBUG_RE, 'Debug');
    unlike($messages, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_info_errors {
    
    plan('tests' => 6);
    
    my ( undef, $errors ) = log_messages($LOG_INFO);
    
    like($errors, $FATAL_RE, 'Fatal');
    like($errors, $ERROR_RE, 'Error');
    like($errors, $WARNING_RE, 'Warning');
    unlike($errors, $INFO_RE, 'Info');
    unlike($errors, $DEBUG_RE, 'Debug');
    unlike($errors, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_debug {
    
    plan('tests' => 2);
    
    subtest('Messages' => \&test_debug_messages);
    subtest('Errors' => \&test_debug_errors);
    
    return done_testing();
    
}


sub test_debug_messages {
    
    plan('tests' => 6);
    
    my ( $messages, undef ) = log_messages($LOG_DEBUG);
    
    unlike($messages, $FATAL_RE, 'Fatal');
    unlike($messages, $ERROR_RE, 'Error');
    unlike($messages, $WARNING_RE, 'Warning');
    like($messages, $INFO_RE, 'Info');
    like($messages, $DEBUG_RE, 'Debug');
    unlike($messages, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_debug_errors {
    
    plan('tests' => 6);
    
    my ( undef, $errors ) = log_messages($LOG_DEBUG);
    
    like($errors, $FATAL_RE, 'Fatal');
    like($errors, $ERROR_RE, 'Error');
    like($errors, $WARNING_RE, 'Warning');
    unlike($errors, $INFO_RE, 'Info');
    unlike($errors, $DEBUG_RE, 'Debug');
    unlike($errors, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_verbose {
    
    plan('tests' => 2);
    
    subtest('Messages' => \&test_verbose_messages);
    subtest('Errors' => \&test_verbose_errors);
    
    return done_testing();
    
}


sub test_verbose_messages {
    
    plan('tests' => 6);
    
    my ( $messages, undef ) = log_messages($LOG_VERBOSE);
    
    unlike($messages, $FATAL_RE, 'Fatal');
    unlike($messages, $ERROR_RE, 'Error');
    unlike($messages, $WARNING_RE, 'Warning');
    like($messages, $INFO_RE, 'Info');
    like($messages, $DEBUG_RE, 'Debug');
    like($messages, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


sub test_verbose_errors {
    
    plan('tests' => 6);
    
    my ( undef, $errors ) = log_messages($LOG_VERBOSE);
    
    like($errors, $FATAL_RE, 'Fatal');
    like($errors, $ERROR_RE, 'Error');
    like($errors, $WARNING_RE, 'Warning');
    unlike($errors, $INFO_RE, 'Info');
    unlike($errors, $DEBUG_RE, 'Debug');
    unlike($errors, $VERBOSE_RE, 'Verbose');
    
    return done_testing();
    
}


1;
