box.session.storage.rettest = function(a)
    return { box.tuple.new({ 'test', a + 1  }) }
end

box.session.storage.create_space = function(space)
    box.schema.space.create(space)
    return 'ok'
end
