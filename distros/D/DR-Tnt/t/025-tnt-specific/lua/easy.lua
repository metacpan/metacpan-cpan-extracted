print(os.getenv('PRIMARY_PORT'))

local box = require 'box';
local port = tonumber(arg[1] or os.getenv('PRIMARY_PORT'))
box.cfg{ listen  = port }

box.schema.user.create('testrwe', { password = 'test', if_not_exists = true });
box.schema.user.grant(
    'testrwe',
    'read,write,execute',
    'universe',
    nil,
    { if_not_exists = true }
);

local fiber = require 'fiber'
local log = require 'log'


_G.lua_ping =
    function()
        return {{ true }}
    end

box.schema.space.create(
    'testspace',
    {
        engine = 'memtx',
        if_not_exists = true,
        id = 1000,
        format = {
            {
                name = 'key',
                type = 'str',
            },
            {
                name = 'value',
                type = 'str'
            }
        }
    }
)

box.space.testspace:create_index(
    'pk',
    {
        type = 'tree',
        unique = true,
        parts = { 1, 'str' }
    }
)

box.schema.user.grant(
    'guest',
    'read,write,execute',
    'universe',
    nil,
    { if_not_exists = true }
)
