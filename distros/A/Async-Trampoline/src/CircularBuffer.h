#pragma once

#include <utility>
#include <stdexcept>

template<class TValue>
class CircularBuffer
{
    TValue* m_storage;
    size_t m_capacity;
    size_t m_size;
    size_t m_start;

    size_t map_index(size_t i) const { return (m_start + i) % capacity(); }

    size_t next_capacity() const
    {
        size_t newcap = 2 * capacity();
        if (newcap == 0) newcap = 1;
        return newcap;
    }

public:

    CircularBuffer() :
        m_storage{nullptr},
        m_capacity{0},
        m_size(0),
        m_start(0)
    {}

    ~CircularBuffer()
    {
        while (size())
            deq();
        if (m_storage)
            delete[] reinterpret_cast<char*>(m_storage);
        m_size = 0;
        m_start = 0;
    }

    /** Number of enqueued elements.
     */
    size_t size() const { return m_size; }

    /** Allocated size.
     */
    size_t capacity() const { return m_capacity; }

    size_t _internal_start() const { return m_start; }

    /** Increase the capacity.
     *
     *  newcapacity: size
     *      Must be larger than current capacity().
     *      Should be power-of-2.
     */
    void grow(size_t newcapacity)
    {
        size_t tail_length = capacity() - m_start;
        if (m_size < tail_length)
            tail_length = m_size;

        TValue* newstorage = reinterpret_cast<TValue*>(
                new char[newcapacity * sizeof(TValue)]);

        // copy the elements to the new storage
        for (size_t i = 0; i < size(); ++i)
        {
            size_t real_ix = map_index(i);
            new (&newstorage[i]) TValue(std::move(m_storage[real_ix]));
            m_storage[real_ix].~TValue();
        }

        delete[] reinterpret_cast<char*>(m_storage);

        m_storage = newstorage;
        m_capacity = newcapacity;
        m_start = 0;  // because elems were stored at beginning
    }

    /** Enqueue a value, growing the buffer if necessary.
     *
     *  value: TValue
     */
    template<class... Args>
    void enq(Args&&... args)
    {
        if (size() == capacity())
        {
            size_t newcapacity = next_capacity();
            grow(newcapacity);
        }

        size_t i = map_index(size());
        new (&m_storage[i]) TValue(std::forward<Args>(args)...);
        m_size++;
    }

    /** Dequeue the oldest value.
     *
     *  Precondition:
     *      size() != 0
     */
    TValue deq()
    {
        assert(size());

        TValue val = std::move(m_storage[m_start]);
        m_storage[m_start].~TValue();

        m_size--;
        m_start = map_index(1);

        return val;
    }

    /** Dequeue the newest value.
     *
     *  Precondition:
     *      size() != 0
     */
    TValue deq_back()
    {
        assert(size());

        m_size--;

        size_t i = map_index(m_size);

        TValue val = std::move(m_storage[i]);
        m_storage[i].~TValue();

        return val;
    }
};

