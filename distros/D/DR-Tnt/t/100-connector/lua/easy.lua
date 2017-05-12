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


_G.sleep = fiber.sleep
_G.rettest = function() return 'test' end

local s = box.schema.space.create('test', {
    temporary   = true,
    format      = {
        { name      = 'name'    },
        { name      = 'value'   },
    }
});
s:create_index('name', { parts = { 1, 'str' } })
