# Global config file for the DBI::BabyConnect.
# This file contains extra configuration parameters for the DBI::BabyConnect
# module. You can delete this file and all extra parameters are set to their
# default.
# DBI::BabyConnect::ExtraParam function will return a string describing what
# these extra parameters has been set to.
# 
DBSETTING_FORCE_SINGLESPACE_FOR_EMPTY_STRING=1

# It is the responsibility of the caller to disconnect. The state of
# the DBI::BabyConnect handle is being checked either when you explicitly call disconnect,
# or when DESTROY is being called (since it is necessary to disconnect upon
# destruction (unless the DBI::BabyConnect instance has been loaded with
# PERSISTENT_OBJECT_ENABLED set to 1)
CALLER_DISCONNECT=0

# used by the developers to print debug information to STDOUT (usually upon DESTROY).
# always set it to 0 unless you know what you are doing.
PRT_CEND=0

# You may not need to set ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT
# to 1 to rollback if you call exit() from within your program 
# (since exit() will eventually call DBI::BabyConnect::DESTROY),
# or if you end the class or program that uses DBI::BabyConnect 
# (as the DESTROY is the last to be called even in Apache::BabyConnect)
# In either case, whenever DESTROY is called, if the autorollback is 1 and autocommit is 0
# and the DBI execute has returned with failure, then the rollback is in effect.

# The caller can always catch and check the return value of a DBI::BabyConnect method
# to see if it has failed a DBI execute. Typically DBI::BabyConnect methods return undef
# whenever a DBI execute fails and therefore the caller can check the return
# value and decide on whether to call the DBI::BabyConnect object method rollback himself or not,
# therefore allowing the caller to continue to work with the instance of DBI::BabyConnect object 
# and its open DBI connection.
# Yet, you can configure the behavior of the DBI::BabyConnect object methods globally
# and tell the object methods to automatically rollback and exit on failure.

# This option is settable and will work only if AutoRollback is in effect for the
# DBI, because DBI::BabyConnect objects delegate all rollbacks to the DBI itself.
# DBI rollback is in effect if and only if:
#  RaiseError is 0 (it should be off because otherwise the DBI would have exited earlier due to the error)
#  AutoCommit is 0 (DBI will have no effect on rollback is AutoCommit is set to 1)
# DBI::BabyConnect will keep track of the success or failure of DBI execute(), hence deciding on
# what to do on failure.
#
# DBI will not exit if the conditions on the rollback are not met, but it will
# continue without effectively rolling back.
#
# For these DBI::BabyConnect objects that have been instantiated by loading the
# DBI::BabyConnect with PERSISTENT_OBJECT_ENABLED set to 1
#    use DBI::BabyConnect 1, 1 
# this option will do a rollback but the exit() is redirected to Apache::exit() as it 
# is documented by mod_perl, in which case only the perl script will exit at this point.
# Refer to perl/testbaby_rollback.pl
# If for any reason the HTTP child is terminated, or the CORE::exit() is called, or CORE::die()
# is called, or anything that will terminate the program and call the DESTROY of a DBI::BabyConnect
# instance, then this DESTROY will still check to see if a rollback conditions are met
# to do an effective rollback; this is different than the behavior of other application
# that do persistence using Apache, as the mechanism of rollback is carried externally of Apache
# handlers and is being dispatched within the DBI::BabyConnect object itself.
ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT=1

# The following is not used
#FORCE_UPPERCASE_ON_ATTRIBUTES

# When ENABLE_STATISTICS_ON_DO is set to 1, a DBI::BabyConnect object maintains
# a table to hold statistics about the do()'s requested by identifying each entry
# with the query string being passed to the do() method. The programmer can
# then call get_do_stat() to get the object that hold the statistics.
# Do not enable this unless you need to collect statistics, for instance in
# data warehousing environment the queries to do() are limited in format
# and are time consuming, so you may desire to collect statistics about these
# do()'s queries.
# 
ENABLE_STATISTICS_ON_DO=0

# When ENABLE_STATISTICS_ON_SPC is set to 1, a DBI::BabyConnect object maintains
# a table to hold statistics about the spc()'s requested by identifying each entry
# with the stored procedure name passed to the spc() method. The programmer can
# then call get_spc_stat() to get the object that hold the statistics.
# Do not enable this unless you need to collect statistics, for instance in
# data warehousing environment the stored procedure names passed spc() are limited in number
# and are time consuming, so you may desire to collect statistics about these
# spc()'s stored procedures.
ENABLE_STATISTICS_ON_SPC=0

