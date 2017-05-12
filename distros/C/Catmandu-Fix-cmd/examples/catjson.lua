#!/usr/bin/env lua
-- requires dkjson http://chiselapp.com/user/dhkolf/repository/dkjson/home
local json = require ("dkjson")

for line in io.lines() do
    local obj, pos, err = json.decode(line, 1, nil)
    print(json.encode(obj))
end