print(os.getenv('PRIMARY_PORT'))

local box = require 'box';
local port = tonumber(arg[1] or os.getenv('PRIMARY_PORT'))
local fiber = require 'fiber'
local log = require 'log'


fiber.sleep(1)



box.cfg{ listen  = port }

box.schema.user.create('testrwe', { password = 'test', if_not_exists = true });
box.schema.user.grant(
    'testrwe',
    'read,write,execute',
    'universe',
    nil,
    { if_not_exists = true }
);

-- box.schema.user.grant(
--     'guest',
--     'read,write,execute',
--     'universe',
--     nil,
--     { if_not_exists = true }
-- );



_G.sleep = fiber.sleep


_G.restart =
    function()
        log.info('Restarting tarantool')
        os.execute('tarantool ' .. arg[0] .. ' ' .. (port + 1))
    end
