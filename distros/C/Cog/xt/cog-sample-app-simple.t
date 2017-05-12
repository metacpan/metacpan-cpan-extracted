#!/usr/bin/env bash

{
  cd "$(dirname $0)"
  source "test-more-bash/init.bash"
  source setup cog-sample-app-simple
}

use Test::More

{
  output="$(
    cd $APP
    cog-sample-app-simple init
  )"
  like "$output" \
    "CogSampleAppSimple was successfully initialized" \
    'App init says it was successful'
#   ok "`[ -f $APP/cog.yaml ]`" \
#     'App init created config file'
}

{
  done_testing
  source teardown
}
