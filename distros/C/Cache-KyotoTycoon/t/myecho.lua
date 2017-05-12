kt = __kyototycoon__
db = kt.db

function myecho(inmap, outmap)
    for key, value in pairs(inmap) do
        outmap[key] = value
    end
    return kt.RVSUCCESS
end
