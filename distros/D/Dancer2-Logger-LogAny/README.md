# NAME

Dancer2::Logger::LogAny - Use Log::Any to log from your Dancer2 app

# DESCRIPTION

This module implements a Dancer2 logging engine using `Log::Any`.
You can then use any `Log::Any::Adapter`-based output class on the backend.

# CONFIGURATION

In your Dancer2 config:

     logger: LogAny
    
     engines:
         logger:
             LogAny:
                 category: Important Messages
                 logger:
                     - Stderr
                     - newline
                     - 1

If you omit the category setting, `Log::Any::Adapter` will use the name of
this class as the category.

The above is a simple configuration example. For a complete working example
app, logging to two different `Log::Dispatch` output engines,  see the
`example/` directory in this module's distribution.

# FUNCTIONS

## log( @args )

This is the function required by `Dancer2::Core::Role::Logger`

# SEE ALSO

`Log::Any`, `Log::Any::Adapter`, `Dancer2::Core::Role::Logger`
