function order_add(oid, pid, oid_in_pid, time, status, sid,
    did, driver_xml, xml, if_status)

    local order = box.select(5, 1, pid, oid_in_pid)

    -- если заказ есть в БД и его статус не соответствует ожидаемому ничего
    -- не делаем
    if if_status ~= nil and order ~= nil and order[4] ~= if_status then
        return
    end

    if order == nil then
        order = box.insert(5, oid, pid, oid_in_pid,
            time, status, sid, did, '', '', driver_xml, xml)
        return order
    end

    if status == 'confirm' and order[4] == 'request' then
        return box.update(
            5,
            order[0],
            '!p=p=p=p=p',

            10,
            xml,

            5,
            sid,

            6,
            did,

            9,
            driver_xml,

            4,
            status
        )
    end

    return box.update(
        5,
        order[0],
        '!p',
        10,
        xml
    )
end

