# Problems

There is no universal module for such inspections

Class::Inspector and Package::Constants can deal with loaded modules only

Module::Info can load modules from file, but can not show constants so need to use Module::Load

So now I stayed at Class::Inspector->functions with Package::Constants 

## Opensource modules tested

https://metacpan.org/pod/Module::Info

https://metacpan.org/pod/Package::Constants

https://metacpan.org/pod/Module::Inspector

https://metacpan.org/pod/Module::Metadata

https://metacpan.org/pod/Class::Inspector

https://metacpan.org/pod/PPI

https://metacpan.org/pod/Devel::Examine::Subs

## Local testing

Each change of App::iperlmoddir you can easily test with 

```
perl -Ilib bin/iperlmoddir -v -d t/samples
```